const express = require('express');
const http = require('http');
const path = require('path');
const fs = require('fs');
const { Server } = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const cron = require('node-cron');
const multer = require('multer');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

dotenv.config();

const JWT_SECRET = process.env.JWT_SECRET || '777usdt_gateway_super_secret_jwt_key_2026';
const uploadDir = path.join(__dirname, 'public', 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `agent_${Date.now()}_${Math.round(Math.random() * 1e9)}${ext}`);
  }
});
const upload = multer({ storage });

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(cors());
app.use(express.json());

// Normalize double /api/api/... paths from any client
app.use((req, res, next) => {
  if (req.url.startsWith('/api/api/')) {
    req.url = req.url.replace(/^\/api\/api\//, '/api/');
  }
  next();
});
app.use(express.static(path.join(__dirname, 'public')));
app.use('/public', express.static(path.join(__dirname, 'public')));

// Health Check & Root Endpoints
app.get(['/', '/health', '/api/health'], (req, res) => {
  res.status(200).json({ status: 'online', service: '777 USDT Gateway API', timestamp: new Date() });
});

// Seller Web Onboarding Landing Page
app.get(['/signup', '/onboard', '/register'], (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'seller_onboard.html'));
});

// Direct APK Download Endpoint for Sellers
app.get(['/download/seller-app.apk', '/download/seller-app', '/download/app'], (req, res) => {
  const primaryApk = path.join(__dirname, 'public', '777_Seller_App.apk');
  const fallbackApk = path.join(__dirname, '..', 'build', 'app', 'outputs', 'flutter-apk', 'app-debug.apk');
  const apkToSend = fs.existsSync(primaryApk) ? primaryApk : fallbackApk;
  if (fs.existsSync(apkToSend)) {
    res.download(apkToSend, '777_Seller_Gateway.apk');
  } else {
    res.status(404).send('APK build currently undergoing update. Please try again shortly.');
  }
});

// Auth Middleware (JWT & legacy fallback)
app.use((req, res, next) => {
  const authHeader = req.headers.authorization;
  if (authHeader) {
    const token = authHeader.startsWith('Bearer ') ? authHeader.split(' ')[1] : authHeader;
    if (token) {
      if (token.startsWith('mock-jwt-token-')) {
        req.userId = token.replace('mock-jwt-token-', '');
      } else if (token === 'mock-seller-token-777') {
        req.userId = 'usr-seller-demo';
      } else {
        try {
          const decoded = jwt.verify(token, JWT_SECRET);
          req.userId = decoded.id;
          req.userRole = decoded.role;
        } catch (err) {
          // Token verification failed or expired
        }
      }
    }
  }
  next();
});

// Helper function to generate JWT token
function generateToken(user) {
  return jwt.sign(
    { id: user._id, role: user.role, email: user.email },
    JWT_SECRET,
    { expiresIn: '30d' }
  );
}

// --- Database Models ---

const userSchema = new mongoose.Schema({
  name: String,
  email: { type: String, unique: true, required: true },
  phone: String,
  password: { type: String, required: true },
  role: { type: String, enum: ['seller', 'partner', 'admin', 'deboarded'], default: 'seller' },
  referralCode: String,
  commissionPercent: { type: Number, default: 0.5 },
  kycStatus: { type: String, default: 'pending' },
  balanceInr: { type: Number, default: 0 }, // For partner commission
  bankDetails: {
    bankName: { type: String, default: '' },
    accountHolderName: { type: String, default: '' },
    accountNumber: { type: String, default: '' },
    ifscCode: { type: String, default: '' },
    upiId: { type: String, default: '' },
    upiQrUrl: { type: String, default: '' }
  },
  upiQrUrl: { type: String, default: '' },
  referredByAgentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  deboardedAt: Date,
  createdAt: { type: Date, default: Date.now }
});
const User = mongoose.model('User', userSchema);

const transactionSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  amountUsdt: Number,
  rateLockedInr: Number,
  network: String,
  txHash: { type: String, unique: true },
  status: { type: String, enum: ['pending', 'verified', 'approved', 'paid', 'rejected'], default: 'pending' },
  payout: {
    reference: String,
    method: String,
    paidAt: Date
  },
  partnerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  commissionAmount: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now }
});
const Transaction = mongoose.model('Transaction', transactionSchema);

const settingsSchema = new mongoose.Schema({
  exchangeRate: { type: Number, default: 92.5 },
  partnerRate: { type: Number, default: 0.50 },
  sellingRate: { type: Number, default: 93.5 },
  defaultAgentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  supportTelegramSeller: { type: String, default: 'https://t.me/G_777_bot' },
  supportTelegramAgent: { type: String, default: 'https://t.me/G_777_agent_desk' },
  supportNotice: { type: String, default: '24x7 Official Telegram Support Desk Active' },
  telegramLink: { type: String, default: 'https://t.me/ugi777_official' },
  wallets: {
    TRC20: { type: String, default: 'TY1H4HqB7777xYzQrT22WpW1xTRX5YVzQp' },
    BEP20: { type: String, default: '0x32A8e9981cB8a9777123992bFc77a90184498f3E' },
    ERC20: { type: String, default: '0x71C949981cB8a9777123992bFc77a90184498f3E' },
    SOL: { type: String, default: '9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin' }
  }
});
const Settings = mongoose.model('Settings', settingsSchema);

const withdrawalSchema = new mongoose.Schema({
  partnerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  amountUsdt: Number,
  amountInr: Number,
  payoutMethod: { type: String, default: 'BANK_TRANSFER' },
  bankDetails: {
    bankName: String,
    accountHolderName: String,
    accountNumber: String,
    ifscCode: String,
    upiId: String
  },
  reference: String,
  status: { type: String, enum: ['pending', 'paid', 'rejected'], default: 'pending' },
  createdAt: { type: Date, default: Date.now }
});
const Withdrawal = mongoose.model('Withdrawal', withdrawalSchema);

// --- Real-time Socket Logic ---
io.on('connection', (socket) => {
  socket.on('join_room', (roomId) => socket.join(roomId));
});

// --- API Endpoints ---

// Auth
app.get('/api/auth/me', async (req, res) => {
  if (!req.userId) {
    return res.status(401).json({ success: false, error: 'Unauthorized or invalid token' });
  }
  try {
    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    const userPayload = {
      id: user._id,
      _id: user._id,
      name: user.name,
      email: user.email,
      phone: user.phone || '',
      role: user.role,
      kycStatus: user.kycStatus || 'verified',
      referredByAgentId: user.referredByAgentId || null,
      createdAt: user.createdAt || new Date().toISOString(),
      merchantCode: "MER-" + user._id.toString().slice(-4).toUpperCase(),
      bankDetails: user.bankDetails || {}
    };
    res.json({ success: true, user: userPayload });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;
  const trimmedEmail = email ? email.toLowerCase().trim() : '';
  const user = await User.findOne({ email: trimmedEmail });
  if (!user) {
    return res.status(404).json({ success: false, error: 'No account found with this email' });
  }

  // Check password with bcrypt (supports plain text fallback for legacy seeded users & auto-hashes)
  let isPasswordValid = false;
  try {
    isPasswordValid = await bcrypt.compare(password, user.password);
  } catch (err) {
    isPasswordValid = false;
  }
  if (!isPasswordValid && user.password === password) {
    isPasswordValid = true;
    // Auto-migrate legacy plain text password to bcrypt hash
    user.password = await bcrypt.hash(password, 10);
    await user.save();
  }

  if (!isPasswordValid) {
    return res.status(401).json({ success: false, error: 'Incorrect password. Please try again' });
  }

  if (user.role === 'deboarded') {
    const Settings = mongoose.model('Settings');
    const settingsObj = await Settings.findOne() || {};
    return res.status(403).json({
      success: false,
      isDeboarded: true,
      error: "You have been Deboarded from the system. Please contact The Support Desk.",
      supportTelegram: settingsObj.supportTelegramAgent || 'https://t.me/G_777_agent_desk'
    });
  }

  const token = generateToken(user);

  const userPayload = {
    id: user._id,
    _id: user._id,
    name: user.name,
    email: user.email,
    phone: user.phone || '',
    role: user.role,
    kycStatus: user.kycStatus || 'verified',
    referredByAgentId: user.referredByAgentId || null,
    createdAt: user.createdAt || new Date().toISOString(),
    merchantCode: "MER-" + user._id.toString().slice(-4).toUpperCase()
  };
  res.json({ success: true, user: userPayload, token });
});

app.post(['/api/auth/signup', '/api/auth/register'], async (req, res) => {
  const { name, email, phone, password, role = 'seller', referralCode, bankDetails } = req.body;
  try {
    const trimmedEmail = email ? email.toLowerCase().trim() : '';
    if (!trimmedEmail) {
      return res.status(400).json({ success: false, error: 'Email is required' });
    }
    const settings = await Settings.findOne() || await Settings.create({});
    let referredByAgentId = null;

    if (referralCode) {
      const trimmed = referralCode.trim();
      const agent = await User.findOne({
        role: "partner",
        $or: [
          { referralCode: new RegExp("^" + trimmed + "$", "i") },
          { _id: mongoose.Types.ObjectId.isValid(trimmed) ? trimmed : null }
        ]
      });
      if (agent) {
        referredByAgentId = agent._id;
        console.log(`[Referral Linked] New seller ${name} linked to Partner ${agent.name} (${agent.referralCode})`);
      }
    }

    if (!referredByAgentId) {
      const defaultPartner = await User.findOne({ role: 'partner' });
      referredByAgentId = settings.defaultAgentId || defaultPartner?._id || null;
    }

    const existing = await User.findOne({ email: trimmedEmail });
    if (existing) {
      return res.status(400).json({ success: false, error: 'An account with this email already exists' });
    }

    const hashedPassword = await bcrypt.hash(password || '123456', 10);

    const newUser = new User({
      name: name || 'Merchant User',
      email: trimmedEmail,
      phone: phone ? phone.trim() : '',
      password: hashedPassword,
      role: 'seller',
      referredByAgentId,
      bankDetails: bankDetails || {}
    });

    await newUser.save();

    if (referredByAgentId) {
      io.emit('merchant_registered', {
        partnerId: referredByAgentId,
        merchant: { id: newUser._id, name: newUser.name, phone: newUser.phone, createdAt: newUser.createdAt }
      });
    }

    const token = generateToken(newUser);

    const userPayload = {
      id: newUser._id,
      _id: newUser._id,
      name: newUser.name,
      email: newUser.email,
      phone: newUser.phone || '',
      role: newUser.role,
      kycStatus: newUser.kycStatus || 'none',
      referredByAgentId: newUser.referredByAgentId || null,
      createdAt: newUser.createdAt || new Date().toISOString(),
      merchantCode: "MER-" + newUser._id.toString().slice(-4).toUpperCase()
    };

    res.json({
      success: true,
      user: userPayload,
      token
    });
  } catch (e) {
    res.status(400).json({ success: false, error: e.message });
  }
});


// Transaction - Deposit (Seller)
app.post(['/api/transactions/deposit', '/api/seller/deposit'], async (req, res) => {
  const { amountUsdt, network, txHash, rateLockedInr } = req.body;
  const userId = req.body.userId || req.userId;
  try {
    let user = await User.findById(userId);
    if (!user && userId === 'usr-seller-demo') {
      user = { referredByAgentId: null }; // Mock user fallback
    }
    let partnerId = user.referredByAgentId;
    let commissionAmount = 0;

    if (partnerId) {
      const partnerUser = await User.findById(partnerId);
      const commPercent = (partnerUser && partnerUser.commissionPercent) ? partnerUser.commissionPercent : 0.50;
      commissionAmount = (amountUsdt * commPercent) / 100;
    }

    const tx = new Transaction({ userId, partnerId, amountUsdt, network, txHash, rateLockedInr, commissionAmount });
    await tx.save();

    io.to('admin_room').emit('new_deposit', tx);
    res.json({ success: true, transaction: tx });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

// Transaction - Update Status (Admin)
app.post('/api/transactions/update-status', async (req, res) => {
  const { txId, status } = req.body;
  const tx = await Transaction.findByIdAndUpdate(txId, { status }, { new: true });
  if (tx) {
    io.to(tx.userId.toString()).emit('status_updated', tx);
    if (tx.partnerId) io.to(tx.partnerId.toString()).emit('commission_updated', tx);
    res.json({ success: true, transaction: tx });
  } else {
    res.status(404).json({ success: false, error: 'Not found' });
  }
});

// ==========================================
// PARTNER / AGENT API SUITE
// ==========================================

// Partner - Dashboard Overview & Real-Time Stats
app.get('/api/partner/dashboard/:partnerId', async (req, res) => {
  try {
    let partner = null;
    if (mongoose.Types.ObjectId.isValid(req.params.partnerId)) {
      partner = await User.findById(req.params.partnerId).lean();
    }
    if (!partner) {
      partner = await User.findOne({ role: 'partner' }).lean();
    }
    if (!partner) return res.status(404).json({ success: false, error: 'Partner not found' });

    const settings = await Settings.findOne() || {};

    if (partner.role === 'deboarded') {
      return res.json({
        success: true,
        isDeboarded: true,
        message: "You have been Deboarded from the system. Please contact The Support Desk.",
        supportTelegram: settings.supportTelegramAgent || 'https://t.me/G_777_agent_desk'
      });
    }
    const totalMerchants = await User.countDocuments({ referredByAgentId: partner._id });

    // Calculate total volume and total commission for referred sellers
    const volStats = await Transaction.aggregate([
      { $match: { partnerId: partner._id, status: { $in: ["verified", "approved", "paid"] } } },
      { $group: { _id: null, totalVolume: { $sum: "$amountUsdt" }, totalCommission: { $sum: "$commissionAmount" }, totalTxCount: { $sum: 1 } } }
    ]);
    const totalVolumeUsdt = volStats[0]?.totalVolume || 0.0;
    const commPercent = partner.commissionPercent !== undefined
      ? partner.commissionPercent
      : (settings.partnerRate || 0.50);

    // If commissionAmount was stored per tx, use it; otherwise compute from totalVolumeUsdt * commPercent %
    const totalCommissionUsdt = volStats[0]?.totalCommission > 0
      ? volStats[0].totalCommission
      : parseFloat((totalVolumeUsdt * (commPercent / 100.0)).toFixed(2));

    const currentExchangeRate = settings.exchangeRate || 92.5;
    const currentSellingRate = settings.sellingRate || 93.5;

    // Total INR Earned matching Admin Panel calculation strictly from transactions:
    const computedBalanceInr = parseFloat((totalCommissionUsdt * currentSellingRate).toFixed(2));
    const baseUsdtBalance = totalCommissionUsdt;

    // Pending withdrawals sum
    const pendingWd = await Withdrawal.aggregate([
      { $match: { partnerId: partner._id, status: "pending" } },
      { $group: { _id: null, totalInr: { $sum: "$amountInr" }, totalUsdt: { $sum: "$amountUsdt" } } }
    ]);
    const pendingWithdrawalInr = pendingWd[0]?.totalInr || 0;

    res.json({
      success: true,
      partner: {
        id: partner._id,
        name: partner.name,
        email: partner.email,
        phone: partner.phone,
        referralCode: partner.referralCode || `AGT-${partner._id.toString().slice(-4).toUpperCase()}`,
        commissionPercent: commPercent,
        balanceInr: computedBalanceInr,
        balanceUsdt: baseUsdtBalance,
        kycStatus: partner.kycStatus || 'verified',
        bankDetails: partner.bankDetails || {}
      },
      stats: {
        totalMerchants,
        availableBalanceInr: computedBalanceInr,
        availableBalanceUsdt: baseUsdtBalance,
        totalCommissionEarnedUsdt: totalCommissionUsdt,
        totalCommissionEarnedInr: computedBalanceInr,
        totalVolumeUsdt,
        pendingWithdrawalInr
      },
      rates: {
        exchangeRate: currentExchangeRate,
        partnerRate: partner.commissionPercent || settings.partnerRate || 0.50,
        commissionPercent: partner.commissionPercent || settings.partnerRate || 0.50,
        sellingRate: settings.sellingRate || 93.5
      }, support: {
        telegramAgent: settings.supportTelegramAgent || 'https://t.me/G_777_agent_desk',
        notice: settings.supportNotice || '24x7 Official Telegram Support Desk Active'
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Partner - Referred Merchants List with Live Volume Aggregates
app.get('/api/partner/merchants/:partnerId', async (req, res) => {
  try {
    const partnerId = req.params.partnerId;
    let actualPartnerId = partnerId;
    if (!mongoose.Types.ObjectId.isValid(partnerId) || !(await User.exists({ _id: partnerId }))) {
      const p = await User.findOne({ role: 'partner' });
      if (p) actualPartnerId = p._id;
    }
    const sellers = await User.find({ referredByAgentId: actualPartnerId }).lean();

    const enrichedSellers = await Promise.all(sellers.map(async (s) => {
      const txAgg = await Transaction.aggregate([
        { $match: { userId: s._id, status: { $in: ["verified", "approved", "paid"] } } },
        { $group: { _id: null, totalUsdt: { $sum: "$amountUsdt" }, count: { $sum: 1 } } }
      ]);
      return {
        id: s._id,
        name: s.name,
        email: s.email,
        phone: s.phone,
        kycStatus: s.kycStatus || 'pending',
        createdAt: s.createdAt,
        totalDepositsCount: txAgg[0]?.count || 0,
        totalUsdtDeposited: txAgg[0]?.totalUsdt || 0
      };
    }));

    res.json({ success: true, merchants: enrichedSellers });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Partner - Commission Ledger Transactions
app.get('/api/partner/transactions/:partnerId', async (req, res) => {
  try {
    const txs = await Transaction.find({ partnerId: req.params.partnerId })
      .populate('userId', 'name email phone')
      .sort({ createdAt: -1 })
      .lean();
    res.json({ success: true, transactions: txs });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Partner - Bank Details Fetch & Update
app.get('/api/partner/bank-details/:partnerId', async (req, res) => {
  try {
    let user = null;
    if (mongoose.Types.ObjectId.isValid(req.params.partnerId)) {
      user = await User.findById(req.params.partnerId).select('bankDetails');
    }
    if (!user) {
      user = await User.findOne({ role: 'partner' }).select('bankDetails');
    }
    res.json({ success: true, bankDetails: user?.bankDetails || {} });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/api/partner/bank-details', async (req, res) => {
  try {
    const { partnerId, bankName, accountHolderName, accountNumber, ifscCode, upiId } = req.body;
    let targetId = partnerId;
    if (!mongoose.Types.ObjectId.isValid(partnerId) || !(await User.exists({ _id: partnerId }))) {
      const p = await User.findOne({ role: 'partner' });
      if (p) targetId = p._id;
    }
    const user = await User.findByIdAndUpdate(
      targetId,
      {
        $set: {
          bankDetails: { bankName, accountHolderName, accountNumber, ifscCode, upiId }
        }
      },
      { new: true }
    );
    res.json({ success: true, bankDetails: user.bankDetails });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Seller - Payout / Bank Details Fetch & Update
app.get(['/api/seller/payout-details', '/api/seller/bank-details'], async (req, res) => {
  try {
    let user = null;
    if (req.userId && mongoose.Types.ObjectId.isValid(req.userId)) {
      user = await User.findById(req.userId);
    }
    if (!user) {
      user = await User.findOne({ role: 'seller' });
    }
    const bank = user?.bankDetails || {};
    res.json({
      success: true,
      accountNumber: bank.accountNumber || '',
      confirmAccountNumber: bank.accountNumber || '',
      ifscCode: bank.ifscCode || '',
      accountHolderName: bank.accountHolderName || user?.name || '',
      upiId: bank.upiId || '',
      upiQrUrl: bank.upiQrUrl || user?.upiQrUrl || '',
      bankName: bank.bankName || ''
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post(['/api/seller/payout-details', '/api/seller/bank-details'], (req, res, next) => {
  upload.single('upiQr')(req, res, (err) => {
    if (err) console.warn('Multer parse warning:', err.message);
    next();
  });
}, async (req, res) => {
  try {
    let user = null;
    if (req.userId && mongoose.Types.ObjectId.isValid(req.userId)) {
      user = await User.findById(req.userId);
    }
    if (!user) {
      user = await User.findOne({ role: 'seller' });
    }
    if (!user) {
      return res.status(404).json({ success: false, error: 'Seller account not found' });
    }

    const { accountNumber, ifscCode, accountHolderName, upiId, bankName } = req.body;
    let upiQrUrl = user.bankDetails?.upiQrUrl || user.upiQrUrl || '';
    if (req.file) {
      upiQrUrl = '/uploads/' + req.file.filename;
    }

    user.bankDetails = {
      accountNumber: (accountNumber !== undefined ? accountNumber : user.bankDetails?.accountNumber) || '',
      ifscCode: (ifscCode !== undefined ? ifscCode : user.bankDetails?.ifscCode) || '',
      accountHolderName: (accountHolderName !== undefined ? accountHolderName : user.bankDetails?.accountHolderName) || '',
      upiId: (upiId !== undefined ? upiId : user.bankDetails?.upiId) || '',
      bankName: (bankName !== undefined ? bankName : user.bankDetails?.bankName) || '',
      upiQrUrl: upiQrUrl
    };
    user.upiQrUrl = upiQrUrl;
    user.markModified('bankDetails');
    await user.save();

    console.log();
    return res.json({
      success: true,
      accountNumber: user.bankDetails.accountNumber,
      ifscCode: user.bankDetails.ifscCode,
      accountHolderName: user.bankDetails.accountHolderName,
      upiId: user.bankDetails.upiId,
      upiQrUrl: user.bankDetails.upiQrUrl,
      bankName: user.bankDetails.bankName
    });
  } catch (err) {
    console.error('❌ Error saving seller payout details:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// Partner - Withdrawal History
app.get('/api/partner/withdrawals/:partnerId', async (req, res) => {
  try {
    let targetId = req.params.partnerId;
    if (!mongoose.Types.ObjectId.isValid(targetId) || !(await User.exists({ _id: targetId }))) {
      const p = await User.findOne({ role: 'partner' });
      if (p) targetId = p._id;
    }
    const wds = await Withdrawal.find({ partnerId: targetId }).sort({ createdAt: -1 });
    res.json({ success: true, withdrawals: wds });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Partner - Request Settlement Withdrawal
app.post('/api/partner/withdraw', async (req, res) => {
  try {
    const { partnerId, amountUsdt, amountInr, payoutMethod } = req.body;
    const partner = await User.findById(partnerId);
    if (!partner) return res.status(404).json({ success: false, error: 'Partner not found' });

    const numInr = parseFloat(amountInr) || 0;
    if (numInr <= 0) return res.status(400).json({ success: false, error: 'Invalid withdrawal amount' });
    if (partner.balanceInr < numInr) {
      return res.status(400).json({ success: false, error: 'Requested amount exceeds available balance' });
    }

    const settings = await Settings.findOne() || {};
    const wd = new Withdrawal({
      partnerId,
      amountUsdt: parseFloat(amountUsdt) || parseFloat((numInr / (settings.exchangeRate || 92.5)).toFixed(2)),
      amountInr: numInr,
      payoutMethod: payoutMethod || 'BANK_TRANSFER',
      bankDetails: partner.bankDetails,
      reference: `WD-${Date.now().toString(36).toUpperCase()}`
    });
    await wd.save();

    partner.balanceInr = Math.max(0, partner.balanceInr - numInr);
    await partner.save();

    io.to('admin_room').emit('new_withdrawal', wd);
    res.json({ success: true, withdrawal: wd, newBalanceInr: partner.balanceInr });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});


// Seller - Dashboard
app.get('/api/seller/dashboard', async (req, res) => {
  if (!req.userId) return res.status(401).json({ error: 'Unauthorized' });

  try {
    // If demo user, return mock transactions
    if (req.userId === 'usr-seller-demo') {
      return res.json({
        kycStatus: 'verified',
        transactions: [
          {
            id: 'mock-tx-1',
            userId: req.userId,
            txHash: '0x123...abc',
            amountUsdt: 100,
            network: 'TRC20',
            rateLockedInr: 92.5,
            status: 'paid',
            createdAt: new Date().toISOString(),
            payout: {
              status: 'paid',
              amountInr: 9250
            }
          }
        ]
      });
    }

    const transactions = await Transaction.find({ userId: req.userId }).lean();

    // Add amountInr to payout dynamically based on rateLockedInr * amountUsdt if not present
    const mappedTxs = transactions.map(tx => {
      let mappedTx = { ...tx, id: tx._id };
      if (mappedTx.payout) {
        mappedTx.payout.amountInr = mappedTx.payout.amountInr || (mappedTx.amountUsdt * (mappedTx.rateLockedInr || 92.5));
      } else if (tx.status === 'paid') {
        mappedTx.payout = {
          status: 'paid',
          amountInr: mappedTx.amountUsdt * (mappedTx.rateLockedInr || 92.5)
        };
      }
      return mappedTx;
    });

    const user = await User.findById(req.userId);
    res.json({
      transactions: mappedTxs,
      kycStatus: user ? user.kycStatus : 'pending'
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Admin Settings (Get & Update)

// --- ADMIN API ENDPOINTS ---

app.get('/api/admin/dashboard', async (req, res) => {
  const User = mongoose.model('User');
  const Transaction = mongoose.model('Transaction');

  const totalUsers = await User.countDocuments({ role: 'seller' });
  const pendingKycCount = await User.countDocuments({ kycStatus: 'pending' });
  const activeAgents = await User.countDocuments({ role: 'partner' });

  const deposits = await Transaction.find();
  const totalVolume = deposits.reduce((sum, d) => sum + (d.amountUsdt || 0), 0);

  res.json({
    totalUsers,
    totalDeposits: deposits.length,
    pendingKycCount,
    totalVolume,
    activeAgents
  });
});

app.get('/api/admin/users', async (req, res) => {
  const User = mongoose.model('User');
  const users = await User.find({ role: 'seller' });
  res.json(users);
});

app.get('/api/admin/deposits', async (req, res) => {
  const Transaction = mongoose.model('Transaction');
  const deposits = await Transaction.find().populate('userId', 'name email kycStatus').populate('partnerId', 'name email');
  res.json(deposits);
});

app.get('/api/admin/payouts', async (req, res) => {
  const Withdrawal = mongoose.model('Withdrawal');
  const payouts = await Withdrawal.find().populate('partnerId', 'name email');
  res.json(payouts);
});

// Admin - Onboard New Partner Agent (Supports both FormData and JSON)
app.post('/api/admin/agents', upload.single('photo'), async (req, res) => {
  try {
    const {
      name,
      phone,
      email,
      password,
      commissionPercent,
      bankName,
      accountHolderName,
      accountNumber,
      ifscCode,
      upiId
    } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ success: false, error: 'Name, email, and password are required.' });
    }

    const User = mongoose.model('User');
    const cleanEmail = email.toLowerCase().trim();
    const existing = await User.findOne({ email: cleanEmail });
    if (existing) {
      return res.status(400).json({ success: false, error: 'An agent with this email already exists in the system.' });
    }

    // Generate clean unique referral code like AGENT007
    const count = await User.countDocuments({ role: 'partner' });
    let codeNum = count + 1;
    let referralCode = `AGENT${codeNum.toString().padStart(3, '0')}`;
    while (await User.exists({ referralCode })) {
      codeNum++;
      referralCode = `AGENT${codeNum.toString().padStart(3, '0')}`;
    }

    const photoUrl = req.file ? `/public/uploads/${req.file.filename}` : '';

    const newAgent = await User.create({
      name: name.trim(),
      email: cleanEmail,
      phone: phone ? phone.trim() : '',
      password: password,
      role: 'partner',
      referralCode,
      commissionPercent: parseFloat(commissionPercent) || 0.50,
      kycStatus: 'verified',
      balanceInr: 0,
      bankDetails: {
        bankName: bankName || '',
        accountHolderName: accountHolderName || name.trim(),
        accountNumber: accountNumber || '',
        ifscCode: ifscCode || '',
        upiId: upiId || ''
      }
    });

    console.log(`✅ [Admin] Successfully onboarded Agent: ${newAgent.name} (${referralCode}) - ${newAgent.email}`);
    io.emit('agent_created', newAgent);

    res.status(201).json({
      success: true,
      agent: {
        id: newAgent._id.toString(),
        _id: newAgent._id,
        name: newAgent.name,
        email: newAgent.email,
        phone: newAgent.phone,
        role: newAgent.role,
        referralCode: newAgent.referralCode,
        commissionPercent: newAgent.commissionPercent,
        kycStatus: newAgent.kycStatus,
        balanceInr: newAgent.balanceInr,
        bankDetails: newAgent.bankDetails,
        totalEarned: 0,
        referredSellers: []
      }
    });
  } catch (err) {
    console.error('❌ Error onboarding agent:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/api/admin/agents', async (req, res) => {
  try {
    const User = mongoose.model('User');
    const Transaction = mongoose.model('Transaction');
    const agents = await User.find({ role: 'partner' }).lean();

    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const enriched = await Promise.all(agents.map(async (agent) => {
      const sellers = await User.find({ referredByAgentId: agent._id }).select('name email phone kycStatus createdAt').lean();
      
      const txSum = await Transaction.aggregate([
        { $match: { partnerId: agent._id, status: { $in: ['verified', 'approved', 'paid'] } } },
        { $group: { _id: null, totalComm: { $sum: '$commissionAmount' }, totalVol: { $sum: '$amountUsdt' } } }
      ]);
      
      const weeklyTxSum = await Transaction.aggregate([
        { 
          $match: { 
            partnerId: agent._id, 
            status: { $in: ['verified', 'approved', 'paid'] },
            createdAt: { $gte: sevenDaysAgo }
          } 
        },
        { $group: { _id: null, weeklyVol: { $sum: '$amountUsdt' } } }
      ]);

      const totalVolumeUsdt = txSum[0]?.totalVol || 0;
      const weeklyVolumeUsdt = weeklyTxSum[0]?.weeklyVol || 0;
      const commPercent = agent.commissionPercent || 0.5;
      const totalCommUsdt = (txSum[0]?.totalComm && txSum[0]?.totalComm > 0) 
        ? txSum[0].totalComm 
        : (totalVolumeUsdt * (commPercent / 100));

      const settingsObj = await mongoose.model('Settings').findOne() || {};
      const agentSellingRate = settingsObj.sellingRate || 93.5;
      const totalCommission = parseFloat((totalCommUsdt * agentSellingRate).toFixed(2));

      return {
        ...agent,
        id: agent._id.toString(),
        referralCode: agent.referralCode || `AGENT001`,
        commissionPercent: commPercent,
        totalVolumeUsdt: parseFloat(totalVolumeUsdt.toFixed(2)),
        weeklyVolumeUsdt: parseFloat(weeklyVolumeUsdt.toFixed(2)),
        totalCommissionUsdt: parseFloat(totalCommUsdt.toFixed(2)),
        referredSellers: sellers,
        totalEarned: totalCommission
      };
    }));

    res.json(enriched);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Deboard Partner Agent (Offboard agent & reassign sellers)
app.delete('/api/admin/agents/:id', async (req, res) => {
  try {
    const User = mongoose.model('User');
    const Settings = mongoose.model('Settings');
    const agentId = req.params.id;

    const agent = await User.findById(agentId);
    if (!agent) {
      return res.status(404).json({ error: 'Agent not found in database' });
    }

    // Identify target agent to reassign sellers
    const settings = await Settings.findOne();
    let targetAgentId = settings?.defaultAgentId;
    if (targetAgentId && targetAgentId.toString() === agentId.toString()) {
      const fallbackPartner = await User.findOne({ role: 'partner', _id: { $ne: agent._id } });
      targetAgentId = fallbackPartner?._id;
      if (settings && targetAgentId) {
        settings.defaultAgentId = targetAgentId;
        await settings.save();
      }
    }

    // Reallocate sellers
    let reallocatedCount = 0;
    if (targetAgentId) {
      const result = await User.updateMany(
        { referredByAgentId: agent._id },
        { referredByAgentId: targetAgentId }
      );
      reallocatedCount = result.modifiedCount;
    } else {
      const result = await User.updateMany(
        { referredByAgentId: agent._id },
        { $unset: { referredByAgentId: 1 } }
      );
      reallocatedCount = result.modifiedCount;
    }

    // Mark role as deboarded
    agent.role = 'deboarded';
    agent.deboardedAt = new Date();
    await agent.save();

    console.log(`🚫 Deboarded agent ${agent.name} (${agent._id}). Reassigned ${reallocatedCount} sellers.`);

    res.json({
      success: true,
      message: `Agent ${agent.name} has been successfully deboarded.`,
      reallocatedCount
    });
  } catch (err) {
    console.error('Deboard agent error:', err);
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/admin/agents/:id/deboard', async (req, res) => {
  // Alias handler pointing to same deboard logic
  const User = mongoose.model('User');
  const agent = await User.findById(req.params.id);
  if (!agent) return res.status(404).json({ error: 'Agent not found' });
  agent.role = 'deboarded';
  agent.deboardedAt = new Date();
  await agent.save();
  res.json({ success: true, message: `Agent ${agent.name} has been deboarded.` });
});

// Update Agent Commission Rate (Supports both PUT and POST from Admin portal)
const handleCommissionUpdate = async (req, res) => {
  try {
    const { commissionPercent } = req.body;
    const User = mongoose.model('User');
    let agent = null;
    if (mongoose.Types.ObjectId.isValid(req.params.id)) {
      agent = await User.findById(req.params.id);
    }
    if (!agent) {
      agent = await User.findOne({ role: 'partner' });
    }
    if (!agent) return res.status(404).json({ error: 'Agent not found' });

    agent.commissionPercent = parseFloat(commissionPercent);
    if (isNaN(agent.commissionPercent)) agent.commissionPercent = 0.5;
    await agent.save();

    // Also update settings.partnerRate for fallback consistency
    try {
      const Settings = mongoose.model('Settings');
      await Settings.updateMany({}, { partnerRate: agent.commissionPercent });
    } catch (e) { }

    console.log();
    io.emit('agent_commission_updated', { agentId: agent._id, commissionPercent: agent.commissionPercent });
    res.json({ success: true, agent, commissionPercent: agent.commissionPercent });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
app.put('/api/admin/agents/:id/commission', handleCommissionUpdate);
app.post('/api/admin/agents/:id/commission', handleCommissionUpdate);

// Update Agent Password (Admin)
const handleAgentPasswordUpdate = async (req, res) => {
  try {
    const { password, newPassword } = req.body;
    const pwd = (newPassword || password || '').trim();
    if (!pwd) {
      return res.status(400).json({ success: false, error: 'Password cannot be empty' });
    }
    const User = mongoose.model('User');
    const agent = await User.findById(req.params.id);
    if (!agent) {
      return res.status(404).json({ success: false, error: 'Agent not found' });
    }
    agent.password = await bcrypt.hash(pwd, 10);
    await agent.save();
    console.log(`🔑 [Admin] Password updated for agent ${agent.name} (${agent.referralCode})`);
    res.json({ success: true, message: `Password updated for agent ${agent.name}` });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};
app.put('/api/admin/agents/:id/password', handleAgentPasswordUpdate);
app.post('/api/admin/agents/:id/password', handleAgentPasswordUpdate);

app.get('/api/admin/logs', async (req, res) => {
  res.json([
    { id: '1', action: 'System Seeded', details: 'Database dummy seed data inserted', user: 'System', timestamp: new Date() }
  ]);
});


app.get('/api/admin/settings', async (req, res) => {
  try {
    let settings = await Settings.findOne();
    if (!settings) settings = await Settings.create({});
    res.json(settings);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/admin/settings', async (req, res) => {
  try {
    const {
      defaultAgentId,
      rateInrPerUsdt,
      exchangeRate,
      sellingRate,
      partnerRate,
      wallets,
      supportTelegramSeller,
      supportTelegramAgent,
      supportNotice,
      telegramLink
    } = req.body;
    let settings = await Settings.findOne();
    if (!settings) settings = await Settings.create({});

    if (defaultAgentId !== undefined) settings.defaultAgentId = defaultAgentId;
    if (rateInrPerUsdt !== undefined) settings.exchangeRate = rateInrPerUsdt;
    if (exchangeRate !== undefined) settings.exchangeRate = exchangeRate;
    if (sellingRate !== undefined) settings.sellingRate = sellingRate;
    if (partnerRate !== undefined) settings.partnerRate = partnerRate;
    if (supportTelegramSeller !== undefined) settings.supportTelegramSeller = supportTelegramSeller;
    if (supportTelegramAgent !== undefined) settings.supportTelegramAgent = supportTelegramAgent;
    if (supportNotice !== undefined) settings.supportNotice = supportNotice;
    if (telegramLink !== undefined) settings.telegramLink = telegramLink;
    if (wallets !== undefined && typeof wallets === "object") {
      settings.wallets = { ...settings.wallets, ...wallets };
    }

    await settings.save();
    io.emit("settings_updated", settings);
    res.json(settings);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Settings (Support /api/public/settings for Seller & Partner apps)
app.get(['/api/public/settings', '/api/settings', '/public/settings'], async (req, res) => {
  let settings = await Settings.findOne() || await Settings.create({});
  res.json(settings);
});


// --- Automated Cron Jobs ---
cron.schedule('0 0 * * 1', async () => {
  if (mongoose.connection.readyState !== 1) return;
  console.log('🔄 Running Weekly Statement Reset...');
  try {
    const txDelete = await Transaction.deleteMany({});
    const wdDelete = await Withdrawal.deleteMany({});
    console.log(`✅ Reset Complete: Deleted ${txDelete.deletedCount} Transactions and ${wdDelete.deletedCount} Withdrawals.`);
    io.emit('weekly_reset', { message: 'All statements have been reset for the new week.' });
  } catch (error) {
    console.error('❌ Weekly Reset Failed:', error);
  }
});

// --- Server Start ---

const PORT = process.env.PORT || 5001;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/777gateway';


const { MongoMemoryServer } = require('mongodb-memory-server');


async function seedDatabase() {
  const User = mongoose.model('User');
  const Transaction = mongoose.model('Transaction');
  const Settings = mongoose.model('Settings');

  const adminCount = await User.countDocuments({ role: 'admin' });
  if (adminCount === 0) {
    const admin = await User.create({ name: 'Super Admin', email: 'admin@777.com', password: 'admin', role: 'admin' });

    const partners = [];
    for (let i = 1; i <= 6; i++) {
      const partner = await User.create({
        name: `Partner Agent ${i}`,
        email: `agent${i}@partner.com`,
        phone: `+91 98765 4321${i}`,
        password: 'password',
        role: 'partner',
        referralCode: `AGENT00${i}`,
        commissionPercent: 0.5,
        balanceInr: 10000 + Math.random() * 50000
      });
      partners.push(partner);

      for (let j = 1; j <= 5; j++) {
        const seller = await User.create({
          name: `Seller ${i}-${j}`,
          email: `seller${i}_${j}@seller.com`,
          password: 'password',
          role: 'seller',
          kycStatus: 'verified',
          referredByAgentId: partner._id
        });

        // Generate high volume transactions for each seller
        for (let k = 1; k <= 8; k++) {
          const isApproved = Math.random() > 0.3;
          const amt = 500 + Math.floor(Math.random() * 5000);
          await Transaction.create({
            userId: seller._id,
            amountUsdt: amt,
            rateLockedInr: 92.0 + Math.random(),
            network: 'TRC20',
            txHash: `0xHASH_${i}_${j}_${k}_${Date.now()}`,
            status: isApproved ? 'approved' : 'pending',
            partnerId: partner._id,
            commissionAmount: (amt * 0.5) / 100, // 0.5% commission (matches real deposit logic)
            createdAt: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000)
          });
        }
      }
    }

    await Settings.create({
      exchangeRate: 92.5,
      partnerRate: 0.50,
      sellingRate: 93.5,
      defaultAgentId: partners[0]._id,
      supportTelegramSeller: 'https://t.me/G_777_bot',
      supportTelegramAgent: 'https://t.me/G_777_agent_desk',
      supportNotice: '24x7 Official Telegram Support Desk Active',
      telegramLink: 'https://t.me/ugi777_official',
      wallets: {
        TRC20: 'TY1H4HqB7777xYzQrT22WpW1xTRX5YVzQp',
        BEP20: '0x32A8e9981cB8a9777123992bFc77a90184498f3E',
        ERC20: '0x71C949981cB8a9777123992bFc77a90184498f3E',
        SOL: '9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin'
      }
    });

    console.log('✅ HUGE Dummy seed data inserted successfully! 6 Agents, 30 Sellers, High Volume!');
  }
}

async function ensureAdminAndSettingsExist() {
  try {
    const User = mongoose.model('User');
    const Settings = mongoose.model('Settings');

    // Check if Super Admin exists
    const adminCount = await User.countDocuments({ role: 'admin' });
    if (adminCount === 0) {
      const hashedPassword = await bcrypt.hash('admin', 10);
      await User.create({
        name: 'Super Admin',
        email: 'admin@777.com',
        password: hashedPassword,
        role: 'admin'
      });
      console.log('✅ Created Super Admin account: admin@777.com / admin');
    }

    // Check if Settings exist
    const settingsCount = await Settings.countDocuments({});
    if (settingsCount === 0) {
      await Settings.create({
        exchangeRate: 92.5,
        partnerRate: 0.50,
        sellingRate: 93.5,
        supportTelegramSeller: 'https://t.me/G_777_bot',
        supportTelegramAgent: 'https://t.me/G_777_agent_desk',
        supportNotice: '24x7 Official Telegram Support Desk Active',
        telegramLink: 'https://t.me/ugi777_official',
        wallets: {
          TRC20: 'TY1H4HqB7777xYzQrT22WpW1xTRX5YVzQp',
          BEP20: '0x32A8e9981cB8a9777123992bFc77a90184498f3E',
          ERC20: '0x71C949981cB8a9777123992bFc77a90184498f3E',
          SOL: '9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin'
        }
      });
      console.log('✅ Initialized default System Settings');
    }

    // Reset legacy dummy balanceInr ghost money for all partners
    await User.updateMany({ role: 'partner' }, { $set: { balanceInr: 0 } });
  } catch (err) {
    console.error('⚠️ Error ensuring Admin & Settings exist:', err.message);
  }
}

async function startServer() {
  try {
    let finalUri = MONGO_URI;
    try {
      await mongoose.connect(MONGO_URI, { serverSelectionTimeoutMS: 5000 });
      console.log('✅ Connected to MongoDB');
      await ensureAdminAndSettingsExist();
    } catch (e) {
      console.log('⚠️ Primary MongoDB not reachable, starting Memory Server for testing...', e.message);
      const mongoServer = await MongoMemoryServer.create();
      finalUri = mongoServer.getUri();
      await mongoose.connect(finalUri);
      await seedDatabase();
      await ensureAdminAndSettingsExist();
      console.log('✅ Connected to In-Memory MongoDB');
    }

    server.listen(PORT, () => {
      console.log(`🚀 Backend running on port ${PORT}`);
    });
  } catch (err) {
    console.log('❌ Fatal DB Connection Error:', err);
  }
}

startServer();
