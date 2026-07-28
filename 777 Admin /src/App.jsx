import React, { useState, useEffect } from 'react';

export default function App() {
  // Config & API Host
  const [apiHost, setApiHost] = useState(() => {
    const saved = localStorage.getItem('admin_api_host');
    return saved || 'http://localhost:5050';
  });
  const [showHostModal, setShowHostModal] = useState(false);
  const [tempHost, setTempHost] = useState(apiHost);

  // Authentication State
  const [token, setToken] = useState(localStorage.getItem('admin_token') || '');
  const [adminUser, setAdminUser] = useState(JSON.parse(localStorage.getItem('admin_user')) || null);
  const [authForm, setAuthForm] = useState({ email: '', password: '' });
  const [authError, setAuthError] = useState('');
  const [authLoading, setAuthLoading] = useState(false);

  // Navigation Tabs
  const [activeTab, setActiveTab] = useState(() => {
    return localStorage.getItem('admin_active_tab') || 'dashboard';
  });

  useEffect(() => {
    localStorage.setItem('admin_active_tab', activeTab);
  }, [activeTab]);

  // Data States
  const [metrics, setMetrics] = useState({
    activeSellers: 0,
    activeAgents: 0,
    totalVolume: 0,
    pendingKyc: 0,
    pendingDeposits: 0,
    pendingPayouts: 0
  });
  const [users, setUsers] = useState([]);
  const [deposits, setDeposits] = useState([]);
  const [payouts, setPayouts] = useState([]);
  const [agents, setAgents] = useState([]);
  const [logs, setLogs] = useState([]);
  
  // Rate & Wallets Config
  const [exchangeRate, setExchangeRate] = useState('');
  const [wallets, setWallets] = useState({ ERC20: '', TRC20: '', BEP20: '', SOL: '' });
  const [erc20File, setErc20File] = useState(null);
  const [trc20File, setTrc20File] = useState(null);
  const [bep20File, setBep20File] = useState(null);
  const [solFile, setSolFile] = useState(null);

  // Detail Modals State
  const [selectedAgentDetail, setSelectedAgentDetail] = useState(null);
  const [selectedDeposit, setSelectedDeposit] = useState(null);
  const [selectedPayout, setSelectedPayout] = useState(null);

  // Helper to resolve dynamic auto-generated or uploaded QR Code URL
  const resolveQrUrl = (address, customQrUrl) => {
    if (customQrUrl) {
      return customQrUrl.startsWith('http') ? customQrUrl : `${apiHost}${customQrUrl}`;
    }
    if (address && address.trim().length > 5) {
      return `https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${encodeURIComponent(address.trim())}`;
    }
    return null;
  };

  // Action Form Inputs
  const [payoutRef, setPayoutRef] = useState('');
  const [payoutFile, setPayoutFile] = useState(null);
  const [actionLoading, setActionLoading] = useState(false);

  // General Loading & Statuses
  const [refreshTrigger, setRefreshTrigger] = useState(0);

  // Onboard Agent States
  const [showOnboardModal, setShowOnboardModal] = useState(false);
  const [onboardForm, setOnboardForm] = useState({
    name: '',
    phone: '',
    email: '',
    password: '',
    commissionPercent: '0.5',
    bankName: '',
    accountHolderName: '',
    accountNumber: '',
    ifscCode: '',
    upiId: ''
  });
  const [onboardError, setOnboardError] = useState('');
  const [onboardSuccess, setOnboardSuccess] = useState(null);
  const [onboardPhotoFile, setOnboardPhotoFile] = useState(null);

  // Fetch Headers Helper
  const getHeaders = () => ({
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  });

  // Save Settings
  const saveHost = () => {
    localStorage.setItem('admin_api_host', tempHost);
    setApiHost(tempHost);
    setShowHostModal(false);
  };

  // Login handler
  const handleLogin = async (e) => {
    e.preventDefault();
    if (!authForm.email || !authForm.password) {
      setAuthError('Please fill in all credentials.');
      return;
    }
    setAuthLoading(true);
    setAuthError('');
    try {
      const res = await fetch(`${apiHost}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(authForm)
      });
      const data = await res.json();
      if (res.ok && data.success) {
        if (data.user.role !== 'admin') {
          setAuthError('Unauthorized. Only Admins can access this panel.');
          return;
        }
        localStorage.setItem('admin_token', data.token);
        localStorage.setItem('admin_user', JSON.stringify(data.user));
        setToken(data.token);
        setAdminUser(data.user);
      } else {
        setAuthError(data.error || 'Authentication failed. Please verify credentials.');
      }
    } catch (err) {
      setAuthError(`Connection error. Failed to connect to server at ${apiHost}`);
    } finally {
      setAuthLoading(false);
    }
  };

  // Logout handler
  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    setToken('');
    setAdminUser(null);
  };

  // Fetch dashboard metrics
  const fetchMetrics = async () => {
    try {
      const res = await fetch(`${apiHost}/api/admin/dashboard`, { headers: getHeaders() });
      if (res.ok) {
        const data = await res.json();
        setMetrics(data);
      }
    } catch (err) {
      console.error('Fetch metrics error:', err.message);
    }
  };

  // Fetch system settings
  const fetchSettings = async () => {
    try {
      const res = await fetch(`${apiHost}/api/admin/settings`, { headers: getHeaders() });
      if (res.ok) {
        const data = await res.json();
        const rateVal = typeof data.exchangeRate === 'object' && data.exchangeRate !== null
          ? data.exchangeRate.rateInrPerUsdt
          : data.exchangeRate;
        setExchangeRate(rateVal ? rateVal.toString() : '88.5');
        setWallets(data.wallets);
      }
    } catch (err) {
      console.error('Fetch settings error:', err.message);
    }
  };

  // Main data loader effect
  useEffect(() => {
    if (!token) return;

    fetchMetrics();
    fetchSettings();

    if (activeTab === 'kyc') {
      fetch(`${apiHost}/api/admin/users`, { headers: getHeaders() })
        .then(res => res.json())
        .then(data => Array.isArray(data) && setUsers(data))
        .catch(err => console.error(err));
    }
    if (activeTab === 'deposits') {
      fetch(`${apiHost}/api/admin/deposits`, { headers: getHeaders() })
        .then(res => res.json())
        .then(data => Array.isArray(data) && setDeposits(data.reverse()))
        .catch(err => console.error(err));
    }
    if (activeTab === 'payouts') {
      fetch(`${apiHost}/api/admin/payouts`, { headers: getHeaders() })
        .then(res => res.json())
        .then(data => Array.isArray(data) && setPayouts(data.reverse()))
        .catch(err => console.error(err));
    }
    if (activeTab === 'agents') {
      fetch(`${apiHost}/api/admin/agents`, { headers: getHeaders() })
        .then(res => res.json())
        .then(data => Array.isArray(data) && setAgents(data))
        .catch(err => console.error(err));
    }
    if (activeTab === 'logs') {
      fetch(`${apiHost}/api/admin/logs`, { headers: getHeaders() })
        .then(res => res.json())
        .then(data => Array.isArray(data) && setLogs(data.reverse()))
        .catch(err => console.error(err));
    }
  }, [token, activeTab, apiHost, refreshTrigger]);

  // Handle KYC verification action
  const handleKycStatus = async (userId, status) => {
    setActionLoading(true);
    try {
      const res = await fetch(`${apiHost}/api/admin/users/${userId}/kyc`, {
        method: 'PUT',
        headers: getHeaders(),
        body: JSON.stringify({ status })
      });
      if (res.ok) {
        alert(`KYC Status successfully updated to: ${status}`);
        setSelectedKycUser(null);
        setRefreshTrigger(p => p + 1);
      } else {
        const errorData = await res.json();
        alert(`Update failed: ${errorData.error || 'Unknown error'}`);
      }
    } catch (err) {
      alert(`Network error: ${err.message}`);
    } finally {
      setActionLoading(false);
    }
  };

  // Handle Deposit verification/confirmation action
  const handleDepositStatus = async (depositId, status) => {
    setActionLoading(true);
    try {
      const res = await fetch(`${apiHost}/api/admin/deposits/${depositId}/status`, {
        method: 'PUT',
        headers: getHeaders(),
        body: JSON.stringify({ status })
      });
      if (res.ok) {
        alert(`Deposit status successfully updated to: ${status}`);
        setSelectedDeposit(null);
        setRefreshTrigger(p => p + 1);
      } else {
        const errorData = await res.json();
        alert(`Update failed: ${errorData.error || 'Unknown error'}`);
      }
    } catch (err) {
      alert(`Network error: ${err.message}`);
    } finally {
      setActionLoading(false);
    }
  };

  // Handle Payout reference & file uploading
  const handlePayoutSubmit = async (e) => {
    e.preventDefault();
    if (!payoutRef) {
      alert('Please fill in UTR reference number.');
      return;
    }
    setActionLoading(true);
    try {
      const formData = new FormData();
      formData.append('payoutReference', payoutRef);
      if (payoutFile) {
        formData.append('payoutScreenshot', payoutFile);
      }

      const res = await fetch(`${apiHost}/api/admin/payouts/${selectedPayout.id}/pay`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`
          // Let browser generate correct boundary headers for multipart/form-data
        },
        body: formData
      });

      if (res.ok) {
        alert('Payout successful. Status updated.');
        setSelectedPayout(null);
        setPayoutRef('');
        setPayoutFile(null);
        setRefreshTrigger(p => p + 1);
      } else {
        const errorData = await res.json();
        alert(`Failed to complete payout: ${errorData.error || 'Unknown error'}`);
      }
    } catch (err) {
      alert(`Network error: ${err.message}`);
    } finally {
      setActionLoading(false);
    }
  };

  // Update System Rate configurations
  const handleUpdateExchangeRate = async (e) => {
    e.preventDefault();
    if (!exchangeRate || parseFloat(exchangeRate) <= 0) {
      alert('Please enter a valid rate.');
      return;
    }
    setActionLoading(true);
    try {
      const res = await fetch(`${apiHost}/api/admin/buy-rate`, {
        method: 'PUT',
        headers: getHeaders(),
        body: JSON.stringify({ rate: parseFloat(exchangeRate) })
      });
      if (res.ok) {
        alert(`Exchange rate successfully updated to: ₹${exchangeRate}`);
        setRefreshTrigger(p => p + 1);
      } else {
        alert('Failed to update live OTC buy rate.');
      }
    } catch (err) {
      alert('Connection error.');
    } finally {
      setActionLoading(false);
    }
  };

  // Update System Wallets
  const handleUpdateWallets = async (e) => {
    e.preventDefault();
    setActionLoading(true);
    try {
      const formData = new FormData();
      formData.append('ERC20', wallets.ERC20 || '');
      formData.append('TRC20', wallets.TRC20 || '');
      formData.append('BEP20', wallets.BEP20 || '');
      formData.append('SOL', wallets.SOL || '');
      if (erc20File) {
        formData.append('erc20Qr', erc20File);
      }
      if (trc20File) {
        formData.append('trc20Qr', trc20File);
      }
      if (bep20File) {
        formData.append('bep20Qr', bep20File);
      }
      if (solFile) {
        formData.append('solQr', solFile);
      }

      const res = await fetch(`${apiHost}/api/admin/settings`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${token}`
        },
        body: formData
      });
      if (res.ok) {
        const data = await res.json();
        alert('Deposit wallets and QR codes updated successfully.');
        setWallets(data.wallets);
        setErc20File(null);
        setTrc20File(null);
        setBep20File(null);
        setSolFile(null);
        setRefreshTrigger(p => p + 1);
      } else {
        alert('Failed to update platform wallet parameters.');
      }
    } catch (err) {
      alert('Connection error.');
    } finally {
      setActionLoading(false);
    }
  };

  // Update Agent commissions rates
  const handleAgentCommission = async (agentId, currentPercent) => {
    const promptValue = prompt('Enter new agent commission rate percentage (0 - 100):', currentPercent);
    if (promptValue === null) return;
    const val = parseFloat(promptValue);
    if (isNaN(val) || val < 0 || val > 100) {
      alert('Please enter a valid percentage between 0 and 100.');
      return;
    }
    setActionLoading(true);
    try {
      const res = await fetch(`${apiHost}/api/admin/agents/${agentId}/commission`, {
        method: 'PUT',
        headers: getHeaders(),
        body: JSON.stringify({ commissionPercent: val })
      });
      if (res.ok) {
        alert('Agent commission percent updated successfully.');
        setRefreshTrigger(p => p + 1);
      } else {
        alert('Failed to update agent details.');
      }
    } catch (err) {
      alert('Network error.');
    } finally {
      setActionLoading(false);
    }
  };

  // Helper to calculate Agent Account Health Status
  const calculateAgentAccountHealth = (agent) => {
    if (!agent) return { percent: 0, status: 'danger', label: '0%', badgeBg: '', badgeColor: '', missingFields: [] };
    let score = 0;
    const totalChecks = 6;
    const missingFields = [];

    // Profile Checks
    if (agent.name) score++; else missingFields.push('Name');
    if (agent.phone) score++; else missingFields.push('Phone');
    if (agent.email) score++; else missingFields.push('Email');
    if (agent.photoUrl) score++; else missingFields.push('Profile Photo');

    // Bank Details Checks
    const bank = agent.bankDetails;
    if (bank && (bank.accountNumber || bank.upiId)) score++; else missingFields.push('Account No / UPI');
    if (bank && (bank.bankName || bank.ifscCode)) score++; else missingFields.push('Bank Name / IFSC');

    const percent = Math.round((score / totalChecks) * 100);

    let status = 'complete'; // complete, warning, danger
    let label = '100% Healthy & Complete';
    let badgeBg = 'rgba(22, 163, 74, 0.15)';
    let badgeColor = '#16a34a';

    if (percent < 100 && percent >= 60) {
      status = 'warning';
      label = `${percent}% Health (Pending Payout Info)`;
      badgeBg = 'rgba(234, 179, 8, 0.15)';
      badgeColor = '#eab308';
    } else if (percent < 60) {
      status = 'danger';
      label = `${percent}% Health (Incomplete Profile)`;
      badgeBg = 'rgba(239, 68, 68, 0.15)';
      badgeColor = '#ef4444';
    }

    return { percent, status, label, badgeBg, badgeColor, missingFields };
  };

  // Handle Onboard Referral Agent (Partner)
  const handleOnboardSubmit = async (e) => {
    e.preventDefault();
    if (!onboardForm.name || !onboardForm.phone || !onboardForm.email || !onboardForm.password) {
      setOnboardError('Please fill in all required fields.');
      return;
    }
    setActionLoading(true);
    setOnboardError('');
    try {
      const formData = new FormData();
      formData.append('name', onboardForm.name);
      formData.append('phone', onboardForm.phone);
      formData.append('email', onboardForm.email);
      formData.append('password', onboardForm.password);
      formData.append('commissionPercent', onboardForm.commissionPercent);
      formData.append('bankName', onboardForm.bankName);
      formData.append('accountHolderName', onboardForm.accountHolderName);
      formData.append('accountNumber', onboardForm.accountNumber);
      formData.append('ifscCode', onboardForm.ifscCode);
      formData.append('upiId', onboardForm.upiId);
      if (onboardPhotoFile) {
        formData.append('photo', onboardPhotoFile);
      }

      const res = await fetch(`${apiHost}/api/admin/agents`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`
        },
        body: formData
      });
      const data = await res.json();
      if (res.ok && data.success) {
        setOnboardSuccess({
          ...data.agent,
          password: onboardForm.password // Keep password for copy-paste
        });
        // Reset form
        setOnboardForm({
          name: '',
          phone: '',
          email: '',
          password: '',
          commissionPercent: '0.5',
          bankName: '',
          accountHolderName: '',
          accountNumber: '',
          ifscCode: '',
          upiId: ''
        });
        setOnboardPhotoFile(null);
        setRefreshTrigger(p => p + 1);
      } else {
        setOnboardError(data.error || 'Failed to onboard referral agent.');
      }
    } catch (err) {
      setOnboardError('Connection error. Failed to communicate with backend.');
    } finally {
      setActionLoading(false);
    }
  };

  // Generate Bank Payout PDF Statement for All Agents (3-Column Vertical Rectangle Box Grid Layout - 9 Cards per A4 Page)
  const handleGenerateAgentPayoutPdf = () => {
    if (!agents || agents.length === 0) {
      alert('No agent profiles found to generate payout statement.');
      return;
    }

    const totalPayoutSum = agents.reduce((sum, a) => sum + (parseFloat(a.totalEarned) || 0), 0);
    const generatedDate = new Date().toLocaleString();

    const printWindow = window.open('', '_blank');
    if (!printWindow) {
      alert('Pop-up blocked. Please allow pop-ups for this site to view the PDF statement.');
      return;
    }

    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <title>777 OTC Gateway - Agent Bank Payout Statement</title>
        <style>
          @page {
            size: A4 portrait;
            margin: 8mm 10mm;
          }
          * {
            box-sizing: border-box;
          }
          body {
            font-family: 'Segoe UI', Arial, sans-serif;
            margin: 0;
            padding: 0;
            color: #0f172a;
            background: #ffffff;
            font-size: 10px;
          }
          .top-header {
            border-bottom: 2px solid #0f172a;
            padding-bottom: 6px;
            margin-bottom: 8px;
            display: flex;
            justify-content: space-between;
            align-items: center;
          }
          .brand-title {
            font-size: 16px;
            font-weight: 800;
            color: #0f172a;
            letter-spacing: 0.5px;
          }
          .brand-sub {
            font-size: 9.5px;
            color: #475569;
          }
          .summary-bar {
            background: #f1f5f9;
            border: 1px solid #cbd5e1;
            border-radius: 4px;
            padding: 6px 10px;
            margin-bottom: 10px;
            display: flex;
            justify-content: space-between;
            font-size: 10px;
            font-weight: 600;
          }
          /* 3 Columns Vertical Rectangle (Khada Box) Grid Layout */
          .rectangle-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 8px;
          }
          .khada-box {
            border: 1.5px solid #0f172a;
            border-radius: 6px;
            padding: 8px;
            background: #ffffff;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            min-height: 175px;
            box-sizing: border-box;
            break-inside: avoid;
            page-break-inside: avoid;
          }
          .box-header {
            background: #0f172a;
            color: #ffffff;
            padding: 4px 6px;
            border-radius: 3px;
            margin-bottom: 6px;
            display: flex;
            justify-content: space-between;
            align-items: center;
          }
          .box-name {
            font-weight: 700;
            font-size: 11px;
          }
          .box-code {
            font-family: monospace;
            font-size: 9.5px;
            color: #38bdf8;
          }
          .box-field {
            border-bottom: 1px dashed #e2e8f0;
            padding: 3px 0;
          }
          .box-field:last-child {
            border-bottom: none;
          }
          .lbl {
            font-size: 8px;
            text-transform: uppercase;
            color: #64748b;
            font-weight: 700;
            display: block;
          }
          .val {
            font-size: 10px;
            font-weight: 700;
            color: #0f172a;
            word-break: break-all;
          }
          .amount-badge {
            background: #f0fdf4;
            border: 1.5px solid #16a34a;
            border-radius: 4px;
            padding: 4px 6px;
            margin-top: 6px;
            text-align: center;
          }
          .amount-lbl {
            font-size: 7.5px;
            text-transform: uppercase;
            font-weight: 700;
            color: #15803d;
          }
          .amount-val {
            font-size: 12px;
            font-weight: 800;
            color: #15803d;
          }
          .footer-note {
            margin-top: 10px;
            padding-top: 6px;
            border-top: 1px solid #cbd5e1;
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 9px;
            color: #64748b;
          }
          .sig-line {
            border-top: 1px solid #000;
            width: 140px;
            text-align: center;
            padding-top: 2px;
            font-weight: 700;
            color: #000;
          }
          @media print {
            body { padding: 0; }
            .khada-box { break-inside: avoid; page-break-inside: avoid; }
          }
        </style>
      </head>
      <body>
        <div class="top-header">
          <div>
            <div class="brand-title">777 OTC GATEWAY</div>
            <div class="brand-sub">AGENT COMMISSION BANK DISBURSEMENT STATEMENT</div>
          </div>
          <div style="text-align: right; font-size: 9px; color: #475569;">
            <div>Date: <strong>${generatedDate}</strong></div>
            <div>Ref: <strong>OTC-PAY-${Date.now().toString().slice(-6)}</strong></div>
          </div>
        </div>

        <div class="summary-bar">
          <div>TOTAL AGENTS: <strong style="color: #0f172a;">${agents.length} AGENTS</strong></div>
          <div>TOTAL DISBURSEMENT: <strong style="color: #15803d;">₹${totalPayoutSum.toLocaleString('en-IN', { minimumFractionDigits: 2 })}</strong></div>
          <div>STATUS: <strong style="color: #2563eb;">APPROVED FOR BANK TRANSFER</strong></div>
        </div>

        <div class="rectangle-grid">
          ${agents.map((agent, index) => {
            const bank = agent.bankDetails || {};
            const acctNo = bank.accountNumber || bank.upiId || 'Not Submitted';
            const acctName = bank.accountHolderName || agent.name;
            const ifsc = bank.ifscCode || (bank.upiId ? 'UPI DIRECT' : 'N/A');
            const bankName = bank.bankName || (bank.upiId ? 'UPI PAY' : 'Bank Account');
            const amount = parseFloat(agent.totalEarned || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 });
            return `
              <div class="khada-box">
                <div>
                  <div class="box-header">
                    <span class="box-name">#${index + 1} ${agent.name}</span>
                    <span class="box-code">${agent.referralCode}</span>
                  </div>
                  
                  <div class="box-field">
                    <span class="lbl">Account Holder Name</span>
                    <span class="val">${acctName}</span>
                  </div>
                  
                  <div class="box-field">
                    <span class="lbl">Bank Name</span>
                    <span class="val" style="color: #2563eb;">${bankName}</span>
                  </div>

                  <div class="box-field">
                    <span class="lbl">Account No / UPI ID</span>
                    <span class="val" style="font-family: monospace; color: #0284c7;">${acctNo}</span>
                  </div>
                  
                  <div class="box-field">
                    <span class="lbl">IFSC Code</span>
                    <span class="val" style="font-family: monospace;">${ifsc}</span>
                  </div>

                  <div class="box-field">
                    <span class="lbl">Agent Contact</span>
                    <span class="val" style="font-size: 9px; color: #475569;">📞 ${agent.phone || 'N/A'}</span>
                  </div>
                </div>

                <div class="amount-badge">
                  <div class="amount-lbl">Net Payout Commission</div>
                  <div class="amount-val">₹${amount}</div>
                </div>
              </div>
            `;
          }).join('')}
        </div>

        <div class="footer-note">
          <div>777 OTC Gateway Accounts Dept — Confidential Bank Disbursement</div>
          <div class="sig-line">AUTHORIZED SIGNATORY</div>
        </div>

        <script>
          window.onload = function() {
            window.print();
          };
        </script>
      </body>
      </html>
    `;

    printWindow.document.write(htmlContent);
    printWindow.document.close();
  };

  // Helper to generate a strong random password
  const generateRandomPassword = () => {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%';
    let pass = '';
    for (let i = 0; i < 10; i++) {
      pass += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    setOnboardForm(prev => ({ ...prev, password: pass }));
  };

  // Login view
  if (!token) {
    return (
      <div className="login-screen">
        <div className="login-glow"></div>
        <div className="login-card">
          <div className="login-logo">🎰</div>
          <h1 className="login-title">777 OTC Admin</h1>
          <p className="login-subtitle" style={{ marginBottom: '1.5rem' }}>Secure Gateway Panel Authorization</p>

          <form onSubmit={handleLogin}>
            <div className="form-group">
              <label className="form-label">Admin Email</label>
              <input
                className="form-input"
                type="email"
                placeholder="admin@777.com"
                value={authForm.email}
                onChange={(e) => setAuthForm({ ...authForm, email: e.target.value })}
              />
            </div>
            
            <div className="form-group">
              <label className="form-label">Password</label>
              <input
                className="form-input"
                type="password"
                placeholder="••••••••"
                value={authForm.password}
                onChange={(e) => setAuthForm({ ...authForm, password: e.target.value })}
              />
            </div>

            {authError && <div style={{ color: 'var(--color-error)', fontSize: '0.85rem', marginBottom: '1.5rem', textAlign: 'left' }}>{authError}</div>}

            <button type="submit" className="form-button" disabled={authLoading}>
              {authLoading ? 'Authenticating...' : 'Sign In To Gateway'}
            </button>
          </form>

          <div className="host-trigger" onClick={() => { setTempHost(apiHost); setShowHostModal(true); }}>
            Configure Server Host ({apiHost})
          </div>
        </div>

        {/* Dynamic API Host Modals */}
        {showHostModal && (
          <div className="modal-overlay">
            <div className="modal-content" style={{ maxWidth: '400px' }}>
              <div className="modal-header">
                <h3 className="modal-title">API Server Config</h3>
                <button className="modal-close" onClick={() => setShowHostModal(false)}>×</button>
              </div>
              <div className="modal-body">
                <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '1rem' }}>
                  Specify the address of your 777 Gateway backend service:
                </p>
                <div className="form-group">
                  <label className="form-label">Backend URL</label>
                  <input
                    className="form-input"
                    type="text"
                    value={tempHost}
                    onChange={(e) => setTempHost(e.target.value)}
                  />
                </div>
              </div>
              <div className="modal-footer">
                <button className="btn btn-secondary" onClick={() => setShowHostModal(false)}>Cancel</button>
                <button className="btn btn-primary" onClick={saveHost}>Save & Apply</button>
              </div>
            </div>
          </div>
        )}
      </div>
    );
  }

  // Dashboard Frame Layout
  return (
    <div className="app-container">
      {/* Sidebar Navigation */}
      <aside className="sidebar">
        <div className="brand-section">
          <span className="brand-logo">🎰</span>
          <span className="brand-title">777 OTC</span>
          <span className="brand-badge">ADMIN</span>
        </div>

        <nav style={{ flexGrow: 1 }}>
          <ul className="sidebar-menu">
            <li className="menu-item">
              <button className={`menu-button ${activeTab === 'dashboard' ? 'active' : ''}`} onClick={() => setActiveTab('dashboard')}>
                <span className="menu-icon">📊</span> Dashboard
              </button>
            </li>

            <li className="menu-item">
              <button className={`menu-button ${activeTab === 'deposits' ? 'active' : ''}`} onClick={() => setActiveTab('deposits')}>
                <span className="menu-icon">💵</span> USDT Deposits
                {metrics.pendingDeposits > 0 && <span style={{ marginLeft: 'auto', background: 'var(--color-warning)', color: '#000', padding: '0.1rem 0.4rem', borderRadius: '10px', fontSize: '0.7rem', fontWeight: 'bold' }}>{metrics.pendingDeposits}</span>}
              </button>
            </li>

            <li className="menu-item">
              <button className={`menu-button ${activeTab === 'agents' ? 'active' : ''}`} onClick={() => setActiveTab('agents')}>
                <span className="menu-icon">🤝</span> Referral Agents
              </button>
            </li>
            <li className="menu-item">
              <button className={`menu-button ${activeTab === 'rates' ? 'active' : ''}`} onClick={() => setActiveTab('rates')}>
                <span className="menu-icon">📈</span> Rate Adjustments
              </button>
            </li>
            <li className="menu-item" style={{ borderLeft: '3px solid var(--accent-cyan)', marginLeft: '12px' }}>
              <button 
                className="menu-button" 
                onClick={() => {
                  setOnboardError('');
                  setOnboardSuccess(null);
                  setShowOnboardModal(true);
                }}
                style={{ paddingLeft: '8px' }}
              >
                <span className="menu-icon">➕</span> Onboard Agent
              </button>
            </li>
            <li className="menu-item">
              <button className={`menu-button ${activeTab === 'settings' ? 'active' : ''}`} onClick={() => setActiveTab('settings')}>
                <span className="menu-icon">⚙️</span> System Config
              </button>
            </li>
            <li className="menu-item">
              <button className={`menu-button ${activeTab === 'logs' ? 'active' : ''}`} onClick={() => setActiveTab('logs')}>
                <span className="menu-icon">📋</span> Audit Log
              </button>
            </li>
          </ul>
        </nav>

        <div className="sidebar-footer">
          <div className="user-info">
            <div className="user-avatar">{adminUser?.name?.substring(0, 2).toUpperCase()}</div>
            <div className="user-details">
              <span className="user-name">{adminUser?.name}</span>
              <span className="user-role">{adminUser?.email}</span>
            </div>
          </div>
          <button className="logout-button" onClick={handleLogout}>Log Out Panel</button>
        </div>
      </aside>

      {/* Main Panel Viewport */}
      <main className="main-content">
        <header className="header-container">
          <div className="page-title-section">
            <h2 className="page-title">
              {activeTab === 'dashboard' && 'Dashboard Summary'}
              {activeTab === 'deposits' && 'USDT Deposits Queue'}
              {activeTab === 'agents' && 'Referral Partner Agents & Accounts'}
              {activeTab === 'rates' && 'Live OTC Rate Adjustments'}
              {activeTab === 'settings' && 'Global System Properties'}
              {activeTab === 'logs' && 'Administrative Audit Trails'}
            </h2>
            <p className="page-subtitle">
              {activeTab === 'dashboard' && 'OTC buying gateway health metric monitoring'}
              {activeTab === 'deposits' && 'Verify blockchain confirmations & trigger payouts'}
              {activeTab === 'agents' && 'Manage agent accounts, payout details, and referred sellers'}
              {activeTab === 'rates' && 'Lock live USDT to INR exchange buy rates'}
              {activeTab === 'settings' && 'Configure 4-chain gateway deposit wallets & QR codes'}
              {activeTab === 'logs' && 'Security records of admin commands logged'}
            </p>
          </div>

          <div className="header-actions">
            <button className="btn-config" onClick={() => { setTempHost(apiHost); setShowHostModal(true); }}>
              ⚙️ Server IP: {apiHost}
            </button>
            <div className="connection-pill">
              <span className="connection-dot"></span>
              Live Gateway Active
            </div>
          </div>
        </header>

        {/* Global Statistics Counters */}
        <section className="metrics-grid">
          <div className="metric-card">
            <div>
              <p className="metric-label">Live Volume</p>
              <h3 className="metric-value">${metrics.totalVolume.toLocaleString()}</h3>
            </div>
            <div className="metric-icon-wrapper metric-icon-purple">💵</div>
          </div>



          <div className="metric-card" onClick={() => setActiveTab('deposits')} style={{ cursor: 'pointer' }}>
            <div>
              <p className="metric-label">Pending Deposits</p>
              <h3 className="metric-value">{metrics.pendingDeposits}</h3>
            </div>
            <div className="metric-icon-wrapper metric-icon-gold">⏳</div>
          </div>


        </section>

        {/* Tab Page: Dashboard Summary */}
        {activeTab === 'dashboard' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
            <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '1.5rem' }}>
              <div className="dashboard-card">
                <div className="card-header">
                  <h3 className="card-title">Live Exchange Information</h3>
                  <span className="badge badge-verified">INR per USDT</span>
                </div>
                <div style={{ fontSize: '2.5rem', fontWeight: '800', color: 'var(--accent-cyan)', marginBottom: '0.5rem' }}>
                  ₹{parseFloat(exchangeRate).toFixed(2)}
                </div>
                <p style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                  Live exchange buy rate locked per USDT deposit across all networks.
                </p>
              </div>

              <div className="dashboard-card" style={{ display: 'flex', flexDirection: 'column' }}>
                <div className="card-header">
                  <h3 className="card-title">Portal Stats</h3>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', flexGrow: 1, justifyContent: 'center' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '0.5rem', borderBottom: '1px solid var(--border-color)' }}>
                    <span style={{ color: 'var(--text-muted)' }}>Total Sellers</span>
                    <span style={{ fontWeight: '700' }}>{metrics.activeSellers}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '0.5rem', borderBottom: '1px solid var(--border-color)' }}>
                    <span style={{ color: 'var(--text-muted)' }}>Registered Agents</span>
                    <span style={{ fontWeight: '700' }}>{metrics.activeAgents}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span style={{ color: 'var(--text-muted)' }}>Server Uptime</span>
                    <span style={{ color: 'var(--color-success)', fontWeight: '700' }}>99.98%</span>
                  </div>
                </div>
              </div>
            </div>

            {/* 4 Blockchain Wallets Card Grid */}
            <div className="dashboard-card">
              <div className="card-header" style={{ marginBottom: '1rem' }}>
                <h3 className="card-title">System Deposit Wallets & QR Codes (4 Blockchains)</h3>
                <button className="btn btn-secondary btn-sm" onClick={() => setActiveTab('settings')}>Configure Wallets ⚙️</button>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '1rem' }}>
                
                {/* ERC20 */}
                <div style={{ padding: '1rem', background: 'rgba(255,255,255,0.02)', borderRadius: '12px', border: '1px solid var(--border-color)', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontWeight: 'bold', fontSize: '0.85rem', color: 'var(--accent-cyan)' }}>Ethereum (ERC20)</span>
                    <span className="badge" style={{ background: 'rgba(0, 242, 254, 0.15)', color: 'var(--accent-cyan)' }}>ERC20</span>
                  </div>
                  <div>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', display: 'block', marginBottom: '0.25rem' }}>Wallet Address:</span>
                    <p style={{ fontSize: '0.8rem', fontFamily: 'monospace', wordBreak: 'break-all', fontWeight: '700', margin: 0, color: wallets.ERC20 ? 'var(--text-color)' : 'var(--text-dimmed)' }}>
                      {wallets.ERC20 || 'Not Configured'}
                    </p>
                  </div>
                  {resolveQrUrl(wallets.ERC20, wallets.erc20QrUrl) ? (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.25rem' }}>
                      <img src={resolveQrUrl(wallets.ERC20, wallets.erc20QrUrl)} alt="ERC20 QR" style={{ width: '64px', height: '64px', objectFit: 'contain', background: 'white', padding: '4px', borderRadius: '6px' }} />
                      <div>
                        <span style={{ fontSize: '0.7rem', color: 'var(--color-success)', fontWeight: 'bold', display: 'block' }}>⚡ Live Sync Active</span>
                        <span style={{ fontSize: '0.65rem', color: 'var(--text-muted)' }}>Auto QR Ready</span>
                      </div>
                    </div>
                  ) : (
                    <div style={{ fontSize: '0.7rem', color: 'var(--text-dimmed)', fontStyle: 'italic' }}>No Address Configured</div>
                  )}
                </div>

                {/* TRC20 */}
                <div style={{ padding: '1rem', background: 'rgba(255,255,255,0.02)', borderRadius: '12px', border: '1px solid var(--border-color)', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontWeight: 'bold', fontSize: '0.85rem', color: 'var(--accent-cyan)' }}>Tron Network (TRC20)</span>
                    <span className="badge" style={{ background: 'rgba(255, 68, 68, 0.15)', color: '#ff4444' }}>TRC20</span>
                  </div>
                  <div>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', display: 'block', marginBottom: '0.25rem' }}>Wallet Address:</span>
                    <p style={{ fontSize: '0.8rem', fontFamily: 'monospace', wordBreak: 'break-all', fontWeight: '700', margin: 0, color: wallets.TRC20 ? 'var(--text-color)' : 'var(--text-dimmed)' }}>
                      {wallets.TRC20 || 'Not Configured'}
                    </p>
                  </div>
                  {resolveQrUrl(wallets.TRC20, wallets.trc20QrUrl) ? (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.25rem' }}>
                      <img src={resolveQrUrl(wallets.TRC20, wallets.trc20QrUrl)} alt="TRC20 QR" style={{ width: '64px', height: '64px', objectFit: 'contain', background: 'white', padding: '4px', borderRadius: '6px' }} />
                      <div>
                        <span style={{ fontSize: '0.7rem', color: 'var(--color-success)', fontWeight: 'bold', display: 'block' }}>⚡ Live Sync Active</span>
                        <span style={{ fontSize: '0.65rem', color: 'var(--text-muted)' }}>Auto QR Ready</span>
                      </div>
                    </div>
                  ) : (
                    <div style={{ fontSize: '0.7rem', color: 'var(--text-dimmed)', fontStyle: 'italic' }}>No Address Configured</div>
                  )}
                </div>

                {/* BEP20 */}
                <div style={{ padding: '1rem', background: 'rgba(255,255,255,0.02)', borderRadius: '12px', border: '1px solid var(--border-color)', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontWeight: 'bold', fontSize: '0.85rem', color: 'var(--accent-cyan)' }}>BNB Chain (BEP20)</span>
                    <span className="badge" style={{ background: 'rgba(255, 187, 51, 0.15)', color: '#ffbb33' }}>BEP20</span>
                  </div>
                  <div>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', display: 'block', marginBottom: '0.25rem' }}>Wallet Address:</span>
                    <p style={{ fontSize: '0.8rem', fontFamily: 'monospace', wordBreak: 'break-all', fontWeight: '700', margin: 0, color: wallets.BEP20 ? 'var(--text-color)' : 'var(--text-dimmed)' }}>
                      {wallets.BEP20 || 'Not Configured'}
                    </p>
                  </div>
                  {resolveQrUrl(wallets.BEP20, wallets.bep20QrUrl) ? (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.25rem' }}>
                      <img src={resolveQrUrl(wallets.BEP20, wallets.bep20QrUrl)} alt="BEP20 QR" style={{ width: '64px', height: '64px', objectFit: 'contain', background: 'white', padding: '4px', borderRadius: '6px' }} />
                      <div>
                        <span style={{ fontSize: '0.7rem', color: 'var(--color-success)', fontWeight: 'bold', display: 'block' }}>⚡ Live Sync Active</span>
                        <span style={{ fontSize: '0.65rem', color: 'var(--text-muted)' }}>Auto QR Ready</span>
                      </div>
                    </div>
                  ) : (
                    <div style={{ fontSize: '0.7rem', color: 'var(--text-dimmed)', fontStyle: 'italic' }}>No Address Configured</div>
                  )}
                </div>

                {/* SOL */}
                <div style={{ padding: '1rem', background: 'rgba(255,255,255,0.02)', borderRadius: '12px', border: '1px solid var(--border-color)', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontWeight: 'bold', fontSize: '0.85rem', color: 'var(--accent-cyan)' }}>Solana (SOL)</span>
                    <span className="badge" style={{ background: 'rgba(153, 69, 255, 0.15)', color: '#9945FF' }}>SOL</span>
                  </div>
                  <div>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', display: 'block', marginBottom: '0.25rem' }}>Wallet Address:</span>
                    <p style={{ fontSize: '0.8rem', fontFamily: 'monospace', wordBreak: 'break-all', fontWeight: '700', margin: 0, color: wallets.SOL ? 'var(--text-color)' : 'var(--text-dimmed)' }}>
                      {wallets.SOL || 'Not Configured'}
                    </p>
                  </div>
                  {resolveQrUrl(wallets.SOL, wallets.solQrUrl) ? (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.25rem' }}>
                      <img src={resolveQrUrl(wallets.SOL, wallets.solQrUrl)} alt="SOL QR" style={{ width: '64px', height: '64px', objectFit: 'contain', background: 'white', padding: '4px', borderRadius: '6px' }} />
                      <div>
                        <span style={{ fontSize: '0.7rem', color: 'var(--color-success)', fontWeight: 'bold', display: 'block' }}>⚡ Live Sync Active</span>
                        <span style={{ fontSize: '0.65rem', color: 'var(--text-muted)' }}>Auto QR Ready</span>
                      </div>
                    </div>
                  ) : (
                    <div style={{ fontSize: '0.7rem', color: 'var(--text-dimmed)', fontStyle: 'italic' }}>No Address Configured</div>
                  )}
                </div>

                {/* SOL */}
                <div style={{ padding: '1rem', background: 'rgba(255,255,255,0.02)', borderRadius: '12px', border: '1px solid var(--border-color)', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontWeight: 'bold', fontSize: '0.85rem', color: 'var(--accent-cyan)' }}>Solana (SOL)</span>
                    <span className="badge" style={{ background: 'rgba(153, 69, 255, 0.15)', color: 'var(--accent-purple)' }}>SOL</span>
                  </div>
                  <div>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', display: 'block', marginBottom: '0.25rem' }}>Wallet Address:</span>
                    <p style={{ fontSize: '0.8rem', fontFamily: 'monospace', wordBreak: 'break-all', fontWeight: '700', margin: 0, color: wallets.SOL ? 'var(--text-color)' : 'var(--text-dimmed)' }}>
                      {wallets.SOL || 'Not Configured'}
                    </p>
                  </div>
                  {wallets.solQrUrl ? (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.25rem' }}>
                      <img src={`${apiHost}${wallets.solQrUrl}`} alt="SOL QR" style={{ width: '64px', height: '64px', objectFit: 'contain', background: 'white', padding: '4px', borderRadius: '6px' }} />
                      <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>QR Code Ready</span>
                    </div>
                  ) : (
                    <div style={{ fontSize: '0.7rem', color: 'var(--text-dimmed)', fontStyle: 'italic' }}>No QR Code uploaded</div>
                  )}
                </div>

              </div>
            </div>
          </div>
        )}



        {/* Tab Page: USDT Deposits Queue */}
        {activeTab === 'deposits' && (
          <div className="dashboard-card">
            <div className="card-header">
              <h3 className="card-title">Blockchain Deposits Received</h3>
            </div>

            <div className="table-responsive">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Seller</th>
                    <th>Network</th>
                    <th>Amount USDT</th>
                    <th>Locked Rate</th>
                    <th>USDT Tx Hash</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {deposits.map((dep) => (
                    <tr key={dep.id}>
                      <td>
                        <div style={{ fontWeight: 'bold' }}>{dep.sellerName}</div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{dep.sellerEmail}</div>
                      </td>
                      <td>
                        <span className="badge badge-paid" style={{ fontSize: '0.65rem' }}>{dep.network}</span>
                      </td>
                      <td style={{ fontWeight: 'bold', color: 'var(--accent-cyan)' }}>
                        {dep.amountUsdt.toFixed(2)} USDT
                      </td>
                      <td>₹{dep.rateLockedInr.toFixed(2)}</td>
                      <td>
                        <a 
                          href={dep.network === 'TRC20' ? `https://tronscan.org/#/transaction/${dep.txHash}` : `https://bscscan.com/tx/${dep.txHash}`}
                          target="_blank" 
                          rel="noreferrer"
                          style={{ color: 'var(--accent-purple)', textDecoration: 'underline', fontFamily: 'monospace', fontSize: '0.8rem' }}
                        >
                          {dep.txHash.substring(0, 10)}...{dep.txHash.substring(dep.txHash.length - 8)} ↗
                        </a>
                      </td>
                      <td>
                        <span className={`badge badge-${dep.status}`}>
                          {dep.status}
                        </span>
                      </td>
                      <td>
                        {dep.status === 'pending' && (
                          <div style={{ display: 'flex', gap: '0.5rem' }}>
                            <button className="btn btn-primary btn-sm" onClick={() => handleDepositStatus(dep.id, 'confirmed')}>
                              Confirm Blockchain
                            </button>
                          </div>
                        )}
                        {dep.status === 'confirmed' && (
                          <button className="btn btn-success btn-sm" onClick={() => handleDepositStatus(dep.id, 'verified')}>
                            Verify & Pay INR
                          </button>
                        )}
                        {dep.status === 'verified' && (
                          <span style={{ fontSize: '0.8rem', color: 'var(--color-success)', fontWeight: 'bold' }}>Processed ✅</span>
                        )}
                        {dep.status === 'rejected' && (
                          <span style={{ fontSize: '0.8rem', color: 'var(--color-error)' }}>Rejected ❌</span>
                        )}
                      </td>
                    </tr>
                  ))}
                  {deposits.length === 0 && (
                    <tr>
                      <td colSpan="7" style={{ textAlign: 'center', color: 'var(--text-dimmed)', padding: '2rem' }}>No deposit transactions logged yet.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}



        {/* Tab Page: Referral Agents */}
        {activeTab === 'agents' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
            <div className="dashboard-card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
              <div>
                <h3 className="card-title">Referral Partner Agents Management</h3>
                <p style={{ color: 'var(--text-muted)', fontSize: '0.85rem', marginTop: '0.25rem' }}>
                  Track agents, inspect account payout details, view referred sellers per agent code, and adjust commission rates.
                </p>
              </div>
              <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
                <button 
                  className="btn btn-secondary" 
                  onClick={handleGenerateAgentPayoutPdf}
                  style={{ background: 'rgba(0, 242, 254, 0.1)', color: 'var(--accent-cyan)', border: '1px solid rgba(0, 242, 254, 0.3)' }}
                >
                  📄 Export Bank Payout PDF Statement
                </button>
                <button 
                  className="btn btn-primary" 
                  onClick={() => {
                    setOnboardError('');
                    setOnboardSuccess(null);
                    setShowOnboardModal(true);
                  }}
                >
                  ➕ Onboard Partner Agent
                </button>
              </div>
            </div>

            {agents.map((agent) => (
              <div className="dashboard-card" key={agent.id} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem', borderLeft: '4px solid var(--accent-cyan)' }}>
                {/* Agent Top Row */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '1rem', borderBottom: '1px solid var(--border-color)', paddingBottom: '1rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                    {agent.photoUrl ? (
                      <img src={`${apiHost}${agent.photoUrl}`} alt={agent.name} style={{ width: '52px', height: '52px', borderRadius: '50%', objectFit: 'cover', border: '2px solid var(--accent-cyan)' }} />
                    ) : (
                      <div style={{ width: '52px', height: '52px', borderRadius: '50%', background: 'rgba(0, 242, 254, 0.12)', color: 'var(--accent-cyan)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.25rem', fontWeight: 'bold', border: '1px solid var(--border-color)' }}>
                        {agent.name ? agent.name.charAt(0).toUpperCase() : '👤'}
                      </div>
                    )}
                    <div>
                      {(() => {
                        const health = calculateAgentAccountHealth(agent);
                        return (
                          <div>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.25rem', flexWrap: 'wrap' }}>
                              <h3 style={{ fontSize: '1.15rem', fontWeight: 'bold', margin: 0 }}>{agent.name}</h3>
                              <span className="badge badge-verified" style={{ fontFamily: 'monospace', fontSize: '0.85rem' }}>
                                Code: {agent.referralCode}
                              </span>
                              <span 
                                className="badge" 
                                style={{ 
                                  background: health.badgeBg, 
                                  color: health.badgeColor, 
                                  border: `1px solid ${health.badgeColor}`, 
                                  fontWeight: 'bold',
                                  fontSize: '0.75rem',
                                  display: 'inline-flex',
                                  alignItems: 'center',
                                  gap: '0.35rem'
                                }}
                              >
                                {health.percent === 100 ? '🟢' : health.percent >= 60 ? '🟡' : '🔴'} {health.label}
                              </span>
                            </div>
                            <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
                              📧 {agent.email} | 📞 {agent.phone}
                            </div>
                            {health.missingFields.length > 0 && (
                              <div style={{ fontSize: '0.75rem', color: '#eab308', marginTop: '0.25rem', fontWeight: '600' }}>
                                ⚠️ Missing Details: <span style={{ color: 'var(--text-color)' }}>{health.missingFields.join(', ')}</span>
                              </div>
                            )}
                          </div>
                        );
                      })()}
                    </div>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                    <div style={{ textAlign: 'right' }}>
                      <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', display: 'block' }}>Commission Rate</span>
                      <span style={{ fontSize: '1.1rem', fontWeight: 'bold', color: 'var(--accent-cyan)' }}>{agent.commissionPercent}%</span>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', display: 'block' }}>Total Earned</span>
                      <span style={{ fontSize: '1.1rem', fontWeight: 'bold', color: 'var(--color-success)' }}>₹{agent.totalEarned?.toLocaleString(undefined, { minimumFractionDigits: 2 }) || '0.00'}</span>
                    </div>
                    <button className="btn btn-primary btn-sm" onClick={() => setSelectedAgentDetail(agent)}>
                      View Full Details & Sellers 🔍
                    </button>
                    <button className="btn btn-secondary btn-sm" onClick={() => handleAgentCommission(agent.id, agent.commissionPercent)}>
                      Adjust Rate ⚙️
                    </button>
                  </div>
                </div>

                {/* Agent Account Details & Referred Sellers Split */}
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '1.5rem' }}>
                  
                  {/* Account / Bank Details Card */}
                  <div style={{ background: 'rgba(255,255,255,0.02)', padding: '1rem', borderRadius: '10px', border: '1px solid var(--border-color)' }}>
                    <h4 style={{ fontSize: '0.85rem', color: 'var(--accent-cyan)', marginBottom: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                      🏦 Agent Payout Account Details
                    </h4>
                    {agent.bankDetails ? (
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', fontSize: '0.8rem' }}>
                        <div>
                          <span style={{ color: 'var(--text-muted)', display: 'block', fontSize: '0.7rem' }}>Account Holder</span>
                          <span style={{ fontWeight: 'bold' }}>{agent.bankDetails.accountHolderName || 'N/A'}</span>
                        </div>
                        <div>
                          <span style={{ color: 'var(--text-muted)', display: 'block', fontSize: '0.7rem' }}>Account / UPI</span>
                          <span style={{ fontWeight: 'bold', color: 'var(--accent-cyan)', fontFamily: 'monospace' }}>
                            {agent.bankDetails.accountNumber || agent.bankDetails.upiId || 'N/A'}
                          </span>
                        </div>
                        {agent.bankDetails.ifscCode && (
                          <div>
                            <span style={{ color: 'var(--text-muted)', display: 'block', fontSize: '0.7rem' }}>IFSC Code</span>
                            <span style={{ fontWeight: 'bold', fontFamily: 'monospace' }}>{agent.bankDetails.ifscCode}</span>
                          </div>
                        )}
                        {agent.bankDetails.bankName && (
                          <div>
                            <span style={{ color: 'var(--text-muted)', display: 'block', fontSize: '0.7rem' }}>Bank Name</span>
                            <span style={{ fontWeight: 'bold' }}>{agent.bankDetails.bankName}</span>
                          </div>
                        )}
                      </div>
                    ) : (
                      <div style={{ fontSize: '0.8rem', color: 'var(--text-dimmed)', fontStyle: 'italic', padding: '0.5rem 0' }}>
                        No payout account details added yet by this agent.
                      </div>
                    )}
                  </div>

                  {/* Referred Sellers List */}
                  <div style={{ background: 'rgba(255,255,255,0.02)', padding: '1rem', borderRadius: '10px', border: '1px solid var(--border-color)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem' }}>
                      <h4 style={{ fontSize: '0.85rem', color: 'var(--accent-purple)', margin: 0, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                        👥 Referred Sellers & USDT Volume ({agent.referredSellers?.length || 0})
                      </h4>
                      <button className="btn btn-secondary btn-sm" style={{ fontSize: '0.75rem', padding: '0.25rem 0.5rem' }} onClick={() => setSelectedAgentDetail(agent)}>
                        Open Tab ↗
                      </button>
                    </div>

                    {agent.referredSellers && agent.referredSellers.length > 0 ? (
                      <div className="table-responsive" style={{ maxHeight: '200px', overflowY: 'auto' }}>
                        <table className="data-table" style={{ fontSize: '0.8rem' }}>
                          <thead>
                            <tr>
                              <th>Seller Name</th>
                              <th>USDT Deposited</th>
                              <th>Seller Bank Account</th>
                              <th>Joined Date</th>
                            </tr>
                          </thead>
                          <tbody>
                            {agent.referredSellers.map((seller) => (
                              <tr key={seller.id}>
                                <td>
                                  <div style={{ fontWeight: 'bold' }}>{seller.name}</div>
                                  <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>{seller.phone}</div>
                                </td>
                                <td>
                                  <span style={{ fontWeight: 'bold', color: 'var(--accent-cyan)' }}>
                                    ${seller.totalUsdtDeposited ? seller.totalUsdtDeposited.toFixed(2) : '0.00'} USDT
                                  </span>
                                </td>
                                <td>
                                  {seller.bankDetails ? (
                                    <span style={{ fontFamily: 'monospace', fontSize: '0.75rem', color: 'var(--text-color)' }}>
                                      {seller.bankDetails.accountNumber || seller.bankDetails.upiId || 'Added'}
                                    </span>
                                  ) : (
                                    <span style={{ color: 'var(--text-dimmed)', fontStyle: 'italic', fontSize: '0.75rem' }}>No Bank</span>
                                  )}
                                </td>
                                <td>{new Date(seller.createdAt).toLocaleDateString()}</td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    ) : (
                      <div style={{ fontSize: '0.8rem', color: 'var(--text-dimmed)', fontStyle: 'italic', padding: '1rem 0', textAlign: 'center' }}>
                        No sellers registered using referral code <span style={{ fontFamily: 'monospace', color: 'var(--accent-cyan)' }}>{agent.referralCode}</span> yet.
                      </div>
                    )}
                  </div>

                </div>
              </div>
            ))}

            {agents.length === 0 && (
              <div className="dashboard-card" style={{ textAlign: 'center', color: 'var(--text-dimmed)', padding: '3rem' }}>
                No referral partner agents registered yet.
              </div>
            )}
          </div>
        )}

        {/* Tab Page: Rate Adjustments */}
        {activeTab === 'rates' && (
          <div style={{ maxWidth: '600px', margin: '0 auto' }}>
            <div className="dashboard-card">
              <div className="card-header" style={{ marginBottom: '0.75rem' }}>
                <h3 className="card-title">📈 Live USDT Rate Adjustments</h3>
                <span className="badge badge-verified">INR per USDT</span>
              </div>
              <p style={{ color: 'var(--text-muted)', fontSize: '0.85rem', marginBottom: '1.5rem' }}>
                Set the live Indian Rupee (INR) exchange rate for USDT sellers across all 4 networks.
              </p>

              <form onSubmit={handleUpdateExchangeRate}>
                <div className="form-group" style={{ marginBottom: '1.5rem' }}>
                  <label className="form-label" style={{ fontSize: '0.9rem', color: 'var(--accent-cyan)' }}>Live Buy Rate (₹ Per USDT)</label>
                  <input
                    className="form-input"
                    type="number"
                    step="0.01"
                    style={{ fontSize: '1.5rem', fontWeight: 'bold', padding: '0.75rem 1rem', color: 'var(--accent-cyan)', textAlign: 'center' }}
                    value={exchangeRate}
                    onChange={(e) => setExchangeRate(e.target.value)}
                    required
                  />
                </div>

                <div style={{ background: 'rgba(0, 242, 254, 0.05)', border: '1px solid rgba(0, 242, 254, 0.2)', padding: '1rem', borderRadius: '10px', marginBottom: '1.5rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem', fontSize: '0.85rem' }}>
                    <span style={{ color: 'var(--text-muted)' }}>Rate for 100 USDT:</span>
                    <span style={{ fontWeight: 'bold', color: 'var(--accent-cyan)' }}>₹{(parseFloat(exchangeRate || 0) * 100).toLocaleString(undefined, { minimumFractionDigits: 2 })}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.85rem' }}>
                    <span style={{ color: 'var(--text-muted)' }}>Rate for 1,000 USDT:</span>
                    <span style={{ fontWeight: 'bold', color: 'var(--accent-cyan)' }}>₹{(parseFloat(exchangeRate || 0) * 1000).toLocaleString(undefined, { minimumFractionDigits: 2 })}</span>
                  </div>
                </div>

                <button type="submit" className="btn btn-primary" style={{ width: '100%', padding: '0.85rem', fontSize: '1rem' }} disabled={actionLoading}>
                  {actionLoading ? 'Updating...' : 'Lock New Live Rate 🔒'}
                </button>
              </form>
            </div>
          </div>
        )}

        {/* Tab Page: System Configuration */}
        {activeTab === 'settings' && (
          <div className="settings-grid">
            <div className="settings-card">
              <div className="card-header" style={{ marginBottom: '0.5rem' }}>
                <h3 className="card-title">Live OTC Buy Rate</h3>
              </div>
              <p style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                Define the Indian Rupee (INR) value locked per single USDT deposit from sellers.
              </p>
              <form onSubmit={handleUpdateExchangeRate}>
                <div className="form-group">
                  <label className="form-label">Rate (₹ Per USDT)</label>
                  <input
                    className="form-input"
                    type="number"
                    step="0.01"
                    value={exchangeRate}
                    onChange={(e) => setExchangeRate(e.target.value)}
                  />
                </div>
                <button type="submit" className="btn btn-primary" style={{ width: '100%' }} disabled={actionLoading}>
                  Update Live Rate
                </button>
              </form>
            </div>

            <div className="settings-card">
              <div className="card-header" style={{ marginBottom: '0.5rem' }}>
                <h3 className="card-title">Multi-Chain Deposit Wallets & QR Codes</h3>
              </div>
              <p style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                Addresses & QR codes for 4 supported blockchains shown inside seller apps. Double check network addresses!
              </p>
              <form onSubmit={handleUpdateWallets}>
                {/* ERC20 Block Chain */}
                <div className="form-group">
                  <label className="form-label" style={{ color: 'var(--accent-cyan)' }}>ERC20 Deposit Wallet (Ethereum)</label>
                  <input
                    className="form-input"
                    style={{ fontFamily: 'monospace', fontSize: '0.85rem', marginBottom: '0.5rem' }}
                    type="text"
                    placeholder="0x..."
                    value={wallets.ERC20 || ''}
                    onChange={(e) => setWallets({ ...wallets, ERC20: e.target.value })}
                  />
                  {resolveQrUrl(wallets.ERC20, wallets.erc20QrUrl) ? (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', margin: '0.5rem 0', background: 'rgba(0, 242, 254, 0.04)', padding: '0.5rem', borderRadius: '8px', border: '1px solid rgba(0, 242, 254, 0.2)' }}>
                      <img src={resolveQrUrl(wallets.ERC20, wallets.erc20QrUrl)} alt="ERC20 QR" style={{ width: '64px', height: '64px', objectFit: 'contain', background: 'white', padding: '3px', borderRadius: '6px' }} />
                      <div>
                        <span style={{ fontSize: '0.75rem', fontWeight: 'bold', color: 'var(--accent-cyan)', display: 'block' }}>⚡ Dynamic Auto QR Code Active</span>
                        <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Auto syncs live to Seller App on save!</span>
                      </div>
                    </div>
                  ) : (
                    <div style={{ fontSize: '0.7rem', color: 'var(--text-dimmed)', fontStyle: 'italic', margin: '0.25rem 0' }}>Type/paste address above to auto-generate QR code</div>
                  )}
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem', marginTop: '0.5rem' }}>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-dimmed)' }}>Optional: Upload custom ERC20 QR Code image:</span>
                    <input
                      type="file"
                      accept="image/*"
                      key={refreshTrigger + '_erc'}
                      onChange={(e) => setErc20File(e.target.files[0])}
                      style={{ color: 'var(--text-muted)', fontSize: '0.75rem' }}
                    />
                  </div>
                </div>

                {/* TRC20 Block Chain */}
                <div className="form-group">
                  <label className="form-label" style={{ color: 'var(--accent-cyan)' }}>TRC20 Deposit Wallet (Tron)</label>
                  <input
                    className="form-input"
                    style={{ fontFamily: 'monospace', fontSize: '0.85rem', marginBottom: '0.5rem' }}
                    type="text"
                    placeholder="T..."
                    value={wallets.TRC20 || ''}
                    onChange={(e) => setWallets({ ...wallets, TRC20: e.target.value })}
                  />
                  {resolveQrUrl(wallets.TRC20, wallets.trc20QrUrl) ? (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', margin: '0.5rem 0', background: 'rgba(0, 242, 254, 0.04)', padding: '0.5rem', borderRadius: '8px', border: '1px solid rgba(0, 242, 254, 0.2)' }}>
                      <img src={resolveQrUrl(wallets.TRC20, wallets.trc20QrUrl)} alt="TRC20 QR" style={{ width: '64px', height: '64px', objectFit: 'contain', background: 'white', padding: '3px', borderRadius: '6px' }} />
                      <div>
                        <span style={{ fontSize: '0.75rem', fontWeight: 'bold', color: 'var(--accent-cyan)', display: 'block' }}>⚡ Dynamic Auto QR Code Active</span>
                        <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Auto syncs live to Seller App on save!</span>
                      </div>
                    </div>
                  ) : (
                    <div style={{ fontSize: '0.7rem', color: 'var(--text-dimmed)', fontStyle: 'italic', margin: '0.25rem 0' }}>Type/paste address above to auto-generate QR code</div>
                  )}
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem', marginTop: '0.5rem' }}>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-dimmed)' }}>Optional: Upload custom TRC20 QR Code image:</span>
                    <input
                      type="file"
                      accept="image/*"
                      key={refreshTrigger + '_trc'}
                      onChange={(e) => setTrc20File(e.target.files[0])}
                      style={{ color: 'var(--text-muted)', fontSize: '0.75rem' }}
                    />
                  </div>
                </div>
                
                {/* BEP20 Block Chain */}
                <div className="form-group">
                  <label className="form-label" style={{ color: 'var(--accent-cyan)' }}>BEP20 Deposit Wallet (BSC)</label>
                  <input
                    className="form-input"
                    style={{ fontFamily: 'monospace', fontSize: '0.85rem', marginBottom: '0.5rem' }}
                    type="text"
                    placeholder="0x..."
                    value={wallets.BEP20 || ''}
                    onChange={(e) => setWallets({ ...wallets, BEP20: e.target.value })}
                  />
                  {resolveQrUrl(wallets.BEP20, wallets.bep20QrUrl) ? (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', margin: '0.5rem 0', background: 'rgba(0, 242, 254, 0.04)', padding: '0.5rem', borderRadius: '8px', border: '1px solid rgba(0, 242, 254, 0.2)' }}>
                      <img src={resolveQrUrl(wallets.BEP20, wallets.bep20QrUrl)} alt="BEP20 QR" style={{ width: '64px', height: '64px', objectFit: 'contain', background: 'white', padding: '3px', borderRadius: '6px' }} />
                      <div>
                        <span style={{ fontSize: '0.75rem', fontWeight: 'bold', color: 'var(--accent-cyan)', display: 'block' }}>⚡ Dynamic Auto QR Code Active</span>
                        <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Auto syncs live to Seller App on save!</span>
                      </div>
                    </div>
                  ) : (
                    <div style={{ fontSize: '0.7rem', color: 'var(--text-dimmed)', fontStyle: 'italic', margin: '0.25rem 0' }}>Type/paste address above to auto-generate QR code</div>
                  )}
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem', marginTop: '0.5rem' }}>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-dimmed)' }}>Optional: Upload custom BEP20 QR Code image:</span>
                    <input
                      type="file"
                      accept="image/*"
                      key={refreshTrigger + '_bep'}
                      onChange={(e) => setBep20File(e.target.files[0])}
                      style={{ color: 'var(--text-muted)', fontSize: '0.75rem' }}
                    />
                  </div>
                </div>

                {/* SOL Block Chain */}
                <div className="form-group">
                  <label className="form-label" style={{ color: 'var(--accent-cyan)' }}>SOL Deposit Wallet (Solana)</label>
                  <input
                    className="form-input"
                    style={{ fontFamily: 'monospace', fontSize: '0.85rem', marginBottom: '0.5rem' }}
                    type="text"
                    placeholder="Solana address..."
                    value={wallets.SOL || ''}
                    onChange={(e) => setWallets({ ...wallets, SOL: e.target.value })}
                  />
                  {wallets.solQrUrl && (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', margin: '0.5rem 0' }}>
                      <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Current SOL QR:</span>
                      <img src={`${apiHost}${wallets.solQrUrl}`} alt="SOL QR" style={{ width: '48px', height: '48px', objectFit: 'contain', background: 'white', padding: '2px', borderRadius: '4px' }} />
                    </div>
                  )}
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-dimmed)' }}>Upload SOL QR Code image:</span>
                    <input
                      type="file"
                      accept="image/*"
                      key={refreshTrigger + '_sol'}
                      onChange={(e) => setSolFile(e.target.files[0])}
                      style={{ color: 'var(--text-muted)', fontSize: '0.75rem' }}
                    />
                  </div>
                </div>
                
                <button type="submit" className="btn btn-primary" style={{ width: '100%', marginTop: '0.5rem' }} disabled={actionLoading}>
                  Update System Wallets (4 Chains)
                </button>
              </form>
            </div>
          </div>
        )}

        {/* Tab Page: Audit Trail logs */}
        {activeTab === 'logs' && (
          <div className="dashboard-card">
            <div className="card-header">
              <h3 className="card-title">Administrative Audit Logs</h3>
            </div>
            
            <div className="log-timeline">
              {logs.map((log) => (
                <div className="log-item" key={log.id}>
                  <span className="log-dot"></span>
                  <div className="log-content">
                    <span className="log-text">{log.actionMessage}</span>
                    <div className="log-meta">
                      <span className="log-admin">{log.adminName}</span>
                      <span>{new Date(log.timestamp).toLocaleString()}</span>
                    </div>
                  </div>
                </div>
              ))}
              {logs.length === 0 && (
                <div style={{ textAlign: 'center', color: 'var(--text-dimmed)', padding: '2rem' }}>No audit trail actions recorded.</div>
              )}
            </div>
          </div>
        )}





        {/* Modal Window: Dedicated Agent Detail & Referred Sellers View */}
        {selectedAgentDetail && (
          <div className="modal-overlay">
            <div className="modal-content" style={{ maxWidth: '850px', width: '90%' }}>
              <div className="modal-header">
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                  {selectedAgentDetail.photoUrl ? (
                    <img src={`${apiHost}${selectedAgentDetail.photoUrl}`} alt={selectedAgentDetail.name} style={{ width: '44px', height: '44px', borderRadius: '50%', objectFit: 'cover', border: '2px solid var(--accent-cyan)' }} />
                  ) : (
                    <div style={{ width: '44px', height: '44px', borderRadius: '50%', background: 'rgba(0, 242, 254, 0.15)', color: 'var(--accent-cyan)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold' }}>
                      {selectedAgentDetail.name ? selectedAgentDetail.name.charAt(0).toUpperCase() : '👤'}
                    </div>
                  )}
                  <div>
                    <h3 className="modal-title">{selectedAgentDetail.name} — Agent Partner Breakdown</h3>
                    <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                      Referral Code: <strong style={{ color: 'var(--accent-cyan)', fontFamily: 'monospace' }}>{selectedAgentDetail.referralCode}</strong> | Email: {selectedAgentDetail.email} | Phone: {selectedAgentDetail.phone}
                    </span>
                  </div>
                </div>
                <button className="modal-close" onClick={() => setSelectedAgentDetail(null)}>×</button>
              </div>

              <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                {/* Agent Metrics Stats Bar */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '1rem', background: 'rgba(255,255,255,0.02)', padding: '1rem', borderRadius: '10px', border: '1px solid var(--border-color)' }}>
                  <div>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', display: 'block' }}>Commission Rate</span>
                    <span style={{ fontSize: '1.2rem', fontWeight: 'bold', color: 'var(--accent-cyan)' }}>{selectedAgentDetail.commissionPercent}%</span>
                  </div>
                  <div>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', display: 'block' }}>Total Commission Earned</span>
                    <span style={{ fontSize: '1.2rem', fontWeight: 'bold', color: 'var(--color-success)' }}>₹{selectedAgentDetail.totalEarned?.toLocaleString(undefined, { minimumFractionDigits: 2 }) || '0.00'}</span>
                  </div>
                  <div>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', display: 'block' }}>Referred Sellers Count</span>
                    <span style={{ fontSize: '1.2rem', fontWeight: 'bold', color: 'var(--accent-purple)' }}>{selectedAgentDetail.referredSellers?.length || 0} Sellers</span>
                  </div>
                </div>

                {/* Agent Account Health Diagnostics Card */}
                {(() => {
                  const health = calculateAgentAccountHealth(selectedAgentDetail);
                  return (
                    <div style={{ background: 'rgba(255,255,255,0.02)', padding: '1rem', borderRadius: '10px', border: '1px solid var(--border-color)' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                        <h4 style={{ fontSize: '0.85rem', color: 'var(--accent-cyan)', margin: 0, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                          🩺 Agent Account Health Status
                        </h4>
                        <span style={{ fontWeight: 'bold', color: health.badgeColor, fontSize: '0.85rem' }}>
                          {health.percent}% Complete
                        </span>
                      </div>

                      <div style={{ width: '100%', height: '8px', background: 'rgba(255,255,255,0.08)', borderRadius: '4px', overflow: 'hidden', marginBottom: '0.75rem' }}>
                        <div style={{ width: `${health.percent}%`, height: '100%', background: health.badgeColor, transition: 'width 0.4s ease' }} />
                      </div>

                      <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                        {health.percent === 100 ? (
                          <span style={{ color: 'var(--color-success)', fontWeight: 'bold' }}>
                            ✅ All profile details, profile photo, and bank payout account info are 100% complete and verified.
                          </span>
                        ) : (
                          <span>
                            ⚠️ Account is missing: <strong style={{ color: '#eab308' }}>{health.missingFields.join(', ')}</strong>. Tell partner agent to update profile in Partner Portal.
                          </span>
                        )}
                      </div>
                    </div>
                  );
                })()}

                {/* Agent Bank Account Details */}
                <div style={{ background: 'rgba(0, 242, 254, 0.03)', padding: '1rem', borderRadius: '10px', border: '1px solid rgba(0, 242, 254, 0.15)' }}>
                  <h4 style={{ fontSize: '0.85rem', color: 'var(--accent-cyan)', marginBottom: '0.5rem', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                    🏦 Agent Bank Payout Account Details
                  </h4>
                  {selectedAgentDetail.bankDetails ? (
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '0.75rem', fontSize: '0.8rem' }}>
                      <div>
                        <span style={{ color: 'var(--text-muted)', fontSize: '0.7rem', display: 'block' }}>Account Holder Name</span>
                        <strong>{selectedAgentDetail.bankDetails.accountHolderName || 'N/A'}</strong>
                      </div>
                      <div>
                        <span style={{ color: 'var(--text-muted)', fontSize: '0.7rem', display: 'block' }}>Account / UPI ID</span>
                        <strong style={{ color: 'var(--accent-cyan)', fontFamily: 'monospace' }}>
                          {selectedAgentDetail.bankDetails.accountNumber || selectedAgentDetail.bankDetails.upiId || 'N/A'}
                        </strong>
                      </div>
                      {selectedAgentDetail.bankDetails.ifscCode && (
                        <div>
                          <span style={{ color: 'var(--text-muted)', fontSize: '0.7rem', display: 'block' }}>IFSC Code</span>
                          <strong style={{ fontFamily: 'monospace' }}>{selectedAgentDetail.bankDetails.ifscCode}</strong>
                        </div>
                      )}
                      {selectedAgentDetail.bankDetails.bankName && (
                        <div>
                          <span style={{ color: 'var(--text-muted)', fontSize: '0.7rem', display: 'block' }}>Bank Name</span>
                          <strong>{selectedAgentDetail.bankDetails.bankName}</strong>
                        </div>
                      )}
                    </div>
                  ) : (
                    <div style={{ fontSize: '0.8rem', color: 'var(--text-dimmed)', fontStyle: 'italic' }}>
                      No payout bank account details added yet by this agent.
                    </div>
                  )}
                </div>

                {/* Referred Sellers Ledger Table */}
                <div>
                  <h4 style={{ fontSize: '0.9rem', color: 'var(--accent-purple)', marginBottom: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    👥 Referred Sellers & USDT Deposit Status ({selectedAgentDetail.referredSellers?.length || 0})
                  </h4>

                  {selectedAgentDetail.referredSellers && selectedAgentDetail.referredSellers.length > 0 ? (
                    <div className="table-responsive" style={{ maxHeight: '250px', overflowY: 'auto' }}>
                      <table className="data-table" style={{ fontSize: '0.8rem' }}>
                        <thead>
                          <tr>
                            <th>Seller Details</th>
                            <th>Status</th>
                            <th>USDT Deposited</th>
                            <th>Seller Bank Account Details</th>
                            <th>Joined Date</th>
                          </tr>
                        </thead>
                        <tbody>
                          {selectedAgentDetail.referredSellers.map((seller) => (
                            <tr key={seller.id}>
                              <td>
                                <div style={{ fontWeight: 'bold' }}>{seller.name}</div>
                                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{seller.email} | {seller.phone}</div>
                              </td>
                              <td>
                                <span className="badge badge-verified" style={{ fontSize: '0.65rem' }}>
                                  Verified Active
                                </span>
                              </td>
                              <td>
                                <div style={{ fontWeight: 'bold', color: 'var(--accent-cyan)' }}>
                                  ${seller.totalUsdtDeposited ? seller.totalUsdtDeposited.toFixed(2) : '0.00'} USDT
                                </div>
                                <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>
                                  {seller.depositCount || 0} deposits
                                </div>
                              </td>
                              <td>
                                {seller.bankDetails ? (
                                  <div style={{ fontSize: '0.75rem' }}>
                                    {seller.bankDetails.upiId ? (
                                      <div><span style={{ color: 'var(--text-muted)' }}>UPI:</span> <strong style={{ color: 'var(--accent-cyan)' }}>{seller.bankDetails.upiId}</strong></div>
                                    ) : (
                                      <div>
                                        <div><strong>{seller.bankDetails.accountHolderName}</strong></div>
                                        <div style={{ fontFamily: 'monospace', color: 'var(--accent-cyan)' }}>{seller.bankDetails.accountNumber} ({seller.bankDetails.ifscCode})</div>
                                      </div>
                                    )}
                                  </div>
                                ) : (
                                  <span style={{ fontSize: '0.75rem', color: 'var(--text-dimmed)', fontStyle: 'italic' }}>No Bank Added</span>
                                )}
                              </td>
                              <td>{new Date(seller.createdAt).toLocaleDateString()}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  ) : (
                    <div style={{ fontSize: '0.85rem', color: 'var(--text-dimmed)', fontStyle: 'italic', padding: '1.5rem', textAlign: 'center', background: 'rgba(255,255,255,0.01)', borderRadius: '8px', border: '1px dashed var(--border-color)' }}>
                      No sellers registered under referral code <strong>{selectedAgentDetail.referralCode}</strong> yet.
                    </div>
                  )}
                </div>
              </div>

              <div className="modal-footer">
                <button className="btn btn-secondary" onClick={() => setSelectedAgentDetail(null)}>Close View</button>
                <button className="btn btn-primary" onClick={() => {
                  const agent = selectedAgentDetail;
                  setSelectedAgentDetail(null);
                  handleAgentCommission(agent.id, agent.commissionPercent);
                }}>
                  Adjust Commission Rate ⚙️
                </button>
              </div>
            </div>
          </div>
        )}
        {showOnboardModal && (
          <div className="modal-overlay">
            <div className="modal-content" style={{ maxWidth: '500px' }}>
              <div className="modal-header">
                <h3 className="modal-title">Onboard Partner Referral Agent</h3>
                <button className="modal-close" onClick={() => { setShowOnboardModal(false); setOnboardSuccess(null); }}>×</button>
              </div>

              {!onboardSuccess ? (
                <form onSubmit={handleOnboardSubmit}>
                  <div className="modal-body">
                    {onboardError && (
                      <div style={{ color: 'var(--color-error)', background: 'rgba(235, 87, 87, 0.1)', padding: '0.75rem', borderRadius: '8px', fontSize: '0.85rem', marginBottom: '1.25rem' }}>
                        ⚠️ {onboardError}
                      </div>
                    )}

                    <div className="form-group">
                      <label className="form-label">Full Name</label>
                      <input
                        className="form-input"
                        type="text"
                        placeholder="e.g. Rajesh Kumar"
                        value={onboardForm.name}
                        onChange={(e) => setOnboardForm({ ...onboardForm, name: e.target.value })}
                        required
                      />
                    </div>

                    <div className="form-group">
                      <label className="form-label">Email Address</label>
                      <input
                        className="form-input"
                        type="email"
                        placeholder="e.g. rajesh@777partner.com"
                        value={onboardForm.email}
                        onChange={(e) => setOnboardForm({ ...onboardForm, email: e.target.value })}
                        required
                      />
                    </div>

                    <div className="form-group">
                      <label className="form-label">Phone Number</label>
                      <input
                        className="form-input"
                        type="tel"
                        placeholder="e.g. 9876543210"
                        value={onboardForm.phone}
                        onChange={(e) => setOnboardForm({ ...onboardForm, phone: e.target.value })}
                        required
                      />
                    </div>

                    <div className="form-group">
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.35rem' }}>
                        <label className="form-label" style={{ marginBottom: 0 }}>Password</label>
                        <button 
                          type="button" 
                          className="btn btn-secondary btn-sm" 
                          onClick={generateRandomPassword}
                          style={{ padding: '0.2rem 0.5rem', fontSize: '0.75rem' }}
                        >
                          ⚡ Generate Secure
                        </button>
                      </div>
                      <input
                        className="form-input"
                        type="text"
                        placeholder="Enter password or generate one"
                        value={onboardForm.password}
                        onChange={(e) => setOnboardForm({ ...onboardForm, password: e.target.value })}
                        required
                      />
                    </div>

                    <div className="form-group">
                      <label className="form-label">Initial Commission Rate (%)</label>
                      <input
                        className="form-input"
                        type="number"
                        step="0.01"
                        min="0"
                        max="100"
                        placeholder="e.g. 0.5"
                        value={onboardForm.commissionPercent}
                        onChange={(e) => setOnboardForm({ ...onboardForm, commissionPercent: e.target.value })}
                        required
                      />
                    </div>

                    <div className="form-group">
                      <label className="form-label">Agent Profile Photo (Optional)</label>
                      <input
                        type="file"
                        accept="image/*"
                        onChange={(e) => setOnboardPhotoFile(e.target.files[0])}
                        style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}
                      />
                    </div>

                    <div style={{ margin: '1.25rem 0 0.5rem 0', borderTop: '1px dashed var(--border-color)', paddingTop: '1rem' }}>
                      <h4 style={{ fontSize: '0.85rem', color: 'var(--accent-cyan)', marginBottom: '0.75rem', textTransform: 'uppercase' }}>
                        🏦 Bank Payout Details (Optional)
                      </h4>

                      <div className="form-group">
                        <label className="form-label">Bank Name</label>
                        <input
                          className="form-input"
                          type="text"
                          placeholder="e.g. HDFC Bank, SBI, ICICI Bank"
                          value={onboardForm.bankName}
                          onChange={(e) => setOnboardForm({ ...onboardForm, bankName: e.target.value })}
                        />
                      </div>

                      <div className="form-group">
                        <label className="form-label">Account Holder Name</label>
                        <input
                          className="form-input"
                          type="text"
                          placeholder="e.g. Rajesh Kumar"
                          value={onboardForm.accountHolderName}
                          onChange={(e) => setOnboardForm({ ...onboardForm, accountHolderName: e.target.value })}
                        />
                      </div>

                      <div className="form-group">
                        <label className="form-label">Account Number / UPI ID</label>
                        <input
                          className="form-input"
                          type="text"
                          placeholder="e.g. 5010023456789 or rajesh@upi"
                          value={onboardForm.accountNumber}
                          onChange={(e) => setOnboardForm({ ...onboardForm, accountNumber: e.target.value })}
                        />
                      </div>

                      <div className="form-group">
                        <label className="form-label">IFSC Code</label>
                        <input
                          className="form-input"
                          type="text"
                          placeholder="e.g. HDFC0001234"
                          value={onboardForm.ifscCode}
                          onChange={(e) => setOnboardForm({ ...onboardForm, ifscCode: e.target.value })}
                        />
                      </div>
                    </div>
                  </div>

                  <div className="modal-footer">
                    <button type="button" className="btn btn-secondary" onClick={() => setShowOnboardModal(false)}>Cancel</button>
                    <button type="submit" className="btn btn-primary" disabled={actionLoading}>
                      {actionLoading ? 'Onboarding...' : 'Onboard Partner'}
                    </button>
                  </div>
                </form>
              ) : (
                <div className="modal-body">
                  <div style={{ textAlign: 'center', margin: '1rem 0' }}>
                    <div style={{ fontSize: '3rem', marginBottom: '0.5rem' }}>🎉</div>
                    <h4 style={{ color: 'var(--color-success)', fontSize: '1.25rem', fontWeight: 'bold' }}>Partner Agent Successfully Onboarded!</h4>
                    <p style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>The referral agent profile is live. Copy these credentials to send to the partner.</p>
                  </div>

                  <div style={{ background: 'rgba(255, 255, 255, 0.02)', border: '1px solid var(--border-color)', borderRadius: '12px', padding: '1.25rem', margin: '1.5rem 0', fontSize: '0.9rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                      <span style={{ color: 'var(--text-muted)' }}>Name:</span>
                      <span style={{ fontWeight: 'bold' }}>{onboardSuccess.name}</span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                      <span style={{ color: 'var(--text-muted)' }}>Email:</span>
                      <span style={{ fontWeight: 'bold', color: 'var(--accent-cyan)' }}>{onboardSuccess.email}</span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                      <span style={{ color: 'var(--text-muted)' }}>Password:</span>
                      <span style={{ fontWeight: 'bold', fontFamily: 'monospace', background: 'rgba(255,255,255,0.05)', padding: '1px 5px', borderRadius: '3px' }}>{onboardSuccess.password}</span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                      <span style={{ color: 'var(--text-muted)' }}>Referral Code:</span>
                      <span style={{ fontWeight: 'bold', color: 'var(--accent-purple)' }}>{onboardSuccess.referralCode}</span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span style={{ color: 'var(--text-muted)' }}>Commission Rate:</span>
                      <span style={{ fontWeight: 'bold', color: 'var(--color-success)' }}>{onboardSuccess.commissionPercent}%</span>
                    </div>
                  </div>

                  <div style={{ display: 'flex', gap: '0.75rem', marginTop: '1.5rem' }}>
                    <button 
                      className="btn btn-secondary" 
                      style={{ flex: 1 }}
                      onClick={() => {
                        const copyText = `🎰 777 USDT Gateway India - Partner Onboarding Details 🎰\n--------------------------------------------------\nWelcome, ${onboardSuccess.name}! You have been onboarded as an Agent/Partner.\n\nCredentials:\nEmail: ${onboardSuccess.email}\nPassword: ${onboardSuccess.password}\n\nReferral Parameters:\nReferral Code: ${onboardSuccess.referralCode}\nCommission Rate: ${onboardSuccess.commissionPercent}%\n\nYou can now log in to the partner app to track your referred sellers and commission.`;
                        navigator.clipboard.writeText(copyText);
                        alert('Onboarding details copied to clipboard!');
                      }}
                    >
                      📋 Copy Partner Details
                    </button>
                    <button 
                      className="btn btn-primary" 
                      style={{ flex: 1 }}
                      onClick={() => {
                        setShowOnboardModal(false);
                        setOnboardSuccess(null);
                      }}
                    >
                      Done & Close
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
