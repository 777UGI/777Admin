import React, { useState, useEffect } from 'react';
import { Eye, EyeOff } from 'lucide-react';

export default function App() {
  // Config & API Host
  const [apiHost, setApiHost] = useState(() => {
    return localStorage.getItem('apiHost') || import.meta.env.VITE_API_BASE_URL || 'http://localhost:5001';
  });
  const [showHostModal, setShowHostModal] = useState(false);
  const [tempHost, setTempHost] = useState(apiHost);

  // Authentication State
  const [token, setToken] = useState(localStorage.getItem('admin_token') || '');
  const [adminUser, setAdminUser] = useState(JSON.parse(localStorage.getItem('admin_user')) || null);
  const [authForm, setAuthForm] = useState({ email: '', password: '' });
  const [authError, setAuthError] = useState('');
  const [authLoading, setAuthLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

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
  const [defaultAgentId, setDefaultAgentId] = useState('');
  const [agentSearchQuery, setAgentSearchQuery] = useState('');
  const [referralAgentSearchQuery, setReferralAgentSearchQuery] = useState('');
  const [sellingRate, setSellingRate] = useState('');
  const [telegramLink, setTelegramLink] = useState('https://t.me/ugi777_official');
  const [supportTelegramSeller, setSupportTelegramSeller] = useState('https://t.me/G_777_bot');
  const [supportTelegramAgent, setSupportTelegramAgent] = useState('https://t.me/G_777_agent_desk');
  const [supportNotice, setSupportNotice] = useState('24x7 Official Telegram Support Desk Active');
  const [copiedWalletNetwork, setCopiedWalletNetwork] = useState(null);
  const [wallets, setWallets] = useState({ ERC20: '', TRC20: '', BEP20: '', SOL: '' });
  const [erc20File, setErc20File] = useState(null);
  const [trc20File, setTrc20File] = useState(null);
  const [bep20File, setBep20File] = useState(null);
  const [solFile, setSolFile] = useState(null);

  // Detail Modals State
  const [selectedAgentDetail, setSelectedAgentDetail] = useState(null);
  const [selectedDeposit, setSelectedDeposit] = useState(null);
  const [selectedPayout, setSelectedPayout] = useState(null);
  const [agentToDeboard, setAgentToDeboard] = useState(null);
  const [showAgentPassword, setShowAgentPassword] = useState(false);
  const [isEditingPassword, setIsEditingPassword] = useState(false);
  const [newAgentPasswordInput, setNewAgentPasswordInput] = useState('');
  const [passwordUpdateLoading, setPasswordUpdateLoading] = useState(false);

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
    localStorage.setItem('apiHost', tempHost);
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
        setExchangeRate(rateVal ? rateVal.toString() : '92.5');
        if (data.sellingRate) setSellingRate(data.sellingRate.toString());
        if (data.wallets) setWallets(data.wallets);
        if (data.defaultAgentId) {
          const rawId = typeof data.defaultAgentId === 'object' && data.defaultAgentId !== null
            ? (data.defaultAgentId._id || data.defaultAgentId.id || String(data.defaultAgentId))
            : String(data.defaultAgentId);
          setDefaultAgentId(rawId);
        }
        if (data.supportTelegramSeller) setSupportTelegramSeller(data.supportTelegramSeller);
        if (data.supportTelegramAgent) setSupportTelegramAgent(data.supportTelegramAgent);
        if (data.supportNotice) setSupportNotice(data.supportNotice);
        if (data.telegramLink) setTelegramLink(data.telegramLink);
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
    if (activeTab === 'agents' || activeTab === 'settings') {
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

  // Open Telegram Test Link in New Tab
  const handleTestOpenTelegram = (linkOrUser) => {
    if (!linkOrUser) {
      alert('Please enter a Telegram handle or link first.');
      return;
    }
    let url = linkOrUser.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.startsWith('@')) url = url.substring(1);
      url = `https://t.me/${url}`;
    }
    window.open(url, '_blank');
  };

  // Copy wallet address to clipboard with feedback
  const handleCopyWalletAddress = (network, address) => {
    if (!address) return;
    navigator.clipboard.writeText(address);
    setCopiedWalletNetwork(network);
    setTimeout(() => setCopiedWalletNetwork(null), 2000);
  };

  // Update Telegram Support Routing
  const handleUpdateSupportConfig = async (e) => {
    e.preventDefault();
    setActionLoading(true);
    try {
      const res = await fetch(`${apiHost}/api/admin/settings`, {
        method: 'PUT',
        headers: getHeaders(),
        body: JSON.stringify({
          supportTelegramSeller,
          supportTelegramAgent,
          supportNotice,
          telegramLink
        })
      });
      if (res.ok) {
        alert('✅ Telegram Support Desk configurations updated successfully! Live links synced.');
        setRefreshTrigger(p => p + 1);
      } else {
        alert('Failed to update support desk configuration.');
      }
    } catch (err) {
      alert(`Network error: ${err.message}`);
    } finally {
      setActionLoading(false);
    }
  };

  const handleUpdateDefaultAgent = async (e) => {
    e.preventDefault();
    setActionLoading(true);
    try {
      const res = await fetch(`${apiHost}/api/admin/settings`, {
        method: 'PUT',
        headers: getHeaders(),
        body: JSON.stringify({ defaultAgentId })
      });
      if (res.ok) {
        alert('✅ Default Agent ID successfully updated.');
        setRefreshTrigger(p => p + 1);
      } else {
        alert('Failed to update Default Agent ID.');
      }
    } catch (err) {
      alert('Connection error.');
    } finally {
      setActionLoading(false);
    }
  };

  // Update System Rate configurations
  const handleUpdateExchangeRate = async (e) => {
    e.preventDefault();
    if (!exchangeRate || parseFloat(exchangeRate) <= 0) {
      alert('Please enter a valid buying rate.');
      return;
    }
    setActionLoading(true);
    try {
      const res = await fetch(`${apiHost}/api/admin/settings`, {
        method: 'PUT',
        headers: getHeaders(),
        body: JSON.stringify({
          exchangeRate: parseFloat(exchangeRate),
          sellingRate: sellingRate ? parseFloat(sellingRate) : undefined
        })
      });
      if (res.ok) {
        alert(`✅ Live OTC Rates successfully updated! Buy: ₹${exchangeRate} | Sell: ₹${sellingRate || 'N/A'}`);
        setRefreshTrigger(p => p + 1);
      } else {
        alert('Failed to update live OTC rates.');
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
      if (erc20File || trc20File || bep20File || solFile) {
        const formData = new FormData();
        formData.append('ERC20', wallets.ERC20 || '');
        formData.append('TRC20', wallets.TRC20 || '');
        formData.append('BEP20', wallets.BEP20 || '');
        formData.append('SOL', wallets.SOL || '');
        if (erc20File) formData.append('erc20Qr', erc20File);
        if (trc20File) formData.append('trc20Qr', trc20File);
        if (bep20File) formData.append('bep20Qr', bep20File);
        if (solFile) formData.append('solQr', solFile);

        const res = await fetch(`${apiHost}/api/admin/settings`, {
          method: 'PUT',
          headers: {
            'Authorization': `Bearer ${token}`
          },
          body: formData
        });
        if (res.ok) {
          const data = await res.json();
          alert('✅ Deposit wallets and custom QR codes updated successfully.');
          if (data.wallets) setWallets(data.wallets);
          setErc20File(null);
          setTrc20File(null);
          setBep20File(null);
          setSolFile(null);
          setRefreshTrigger(p => p + 1);
        } else {
          alert('Failed to update platform wallet parameters.');
        }
      } else {
        const res = await fetch(`${apiHost}/api/admin/settings`, {
          method: 'PUT',
          headers: getHeaders(),
          body: JSON.stringify({
            wallets: {
              TRC20: wallets.TRC20 || '',
              ERC20: wallets.ERC20 || '',
              BEP20: wallets.BEP20 || '',
              SOL: wallets.SOL || ''
            }
          })
        });
        if (res.ok) {
          const data = await res.json();
          alert('✅ Multi-chain deposit wallets updated successfully.');
          if (data.wallets) setWallets(data.wallets);
          setRefreshTrigger(p => p + 1);
        } else {
          alert('Failed to update platform wallet parameters.');
        }
      }
    } catch (err) {
      alert(`Connection error: ${err.message}`);
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

  // Update Agent Password (Admin)
  const handleUpdateAgentPassword = async (agentId) => {
    if (!newAgentPasswordInput.trim()) {
      alert('Please enter a valid new password!');
      return;
    }
    setPasswordUpdateLoading(true);
    try {
      const res = await fetch(`${apiHost}/api/admin/agents/${agentId}/password`, {
        method: 'PUT',
        headers: getHeaders(),
        body: JSON.stringify({ newPassword: newAgentPasswordInput.trim() })
      });
      const data = await res.json();
      if (res.ok && data.success) {
        alert(`✅ Password successfully updated for ${selectedAgentDetail?.name || "Agent"}! New password: ${data.password}`);
        setSelectedAgentDetail(prev => ({ ...prev, password: data.password }));
        setAgents(prev => prev.map(a => (a.id === agentId || a._id === agentId) ? { ...a, password: data.password } : a));
        setIsEditingPassword(false);
        setNewAgentPasswordInput('');
        setShowAgentPassword(true);
      } else {
        alert(data.error || 'Failed to update password');
      }
    } catch (err) {
      alert(`Connection error: ${err.message}`);
    } finally {
      setPasswordUpdateLoading(false);
    }
  };

  // Deboard Partner Agent Handlers
  const handleDeboardAgent = (agent) => {
    setAgentToDeboard(agent);
  };

  const confirmDeboardAgent = async () => {
    if (!agentToDeboard) return;
    const agentId = agentToDeboard.id || agentToDeboard._id;
    setActionLoading(true);
    try {
      const res = await fetch(`${apiHost}/api/admin/agents/${agentId}`, {
        method: 'DELETE',
        headers: getHeaders()
      });
      const data = await res.json();
      if (res.ok) {
        alert(`✅ Agent "${agentToDeboard.name}" has been successfully deboarded from the system!${data.reallocatedCount ? '\n' + data.reallocatedCount + ' referred sellers were safely reassigned to the default platform partner.' : ''}`);
        setAgentToDeboard(null);
        if (selectedAgentDetail && (selectedAgentDetail.id === agentId || selectedAgentDetail._id === agentId)) {
          setSelectedAgentDetail(null);
        }
        setRefreshTrigger(p => p + 1);
      } else {
        alert(data.error || 'Failed to deboard agent.');
      }
    } catch (err) {
      alert(`Network error: ${err.message}`);
    } finally {
      setActionLoading(false);
    }
  };

  // Helper to calculate Agent Account Health Status
  const calculateAgentAccountHealth = (agent) => {
    if (!agent) return { percent: 0, status: 'danger', label: '0%', badgeBg: '', badgeColor: '', missingFields: [] };
    let score = 0;
    const totalChecks = 5;
    const missingFields = [];

    // Profile Checks
    if (agent.name) score++; else missingFields.push('Name');
    if (agent.phone) score++; else missingFields.push('Phone');
    if (agent.email) score++; else missingFields.push('Email');

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
        <title>777 UGI Gateway - Agent Bank Payout Statement</title>
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
            <div class="brand-title">777 UGI GATEWAY</div>
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
          <div>777 UGI Gateway Accounts Dept — Confidential Bank Disbursement</div>
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
          <div className="login-logo" style={{display: "none"}}></div>
          <h1 className="login-title">Welcome Admin 777</h1>
          <p className="login-subtitle" style={{ marginBottom: '1.5rem' }}>Secure Gateway Panel Authorization</p>

          <form onSubmit={handleLogin}>
            <div className="form-group">
              <label className="form-label">Admin Username</label>
              <input
                className="form-input"
                type="text"
                placeholder=""
                value={authForm.email}
                onChange={(e) => setAuthForm({ ...authForm, email: e.target.value })}
              />
            </div>
            
            <div className="form-group">
              <label className="form-label">Password</label>
              <div style={{ position: 'relative' }}>
                <input
                  className="form-input"
                  style={{ width: '100%', paddingRight: '50px', boxSizing: 'border-box' }}
                  type={showPassword ? "text" : "password"}
                  placeholder=""
                  value={authForm.password}
                  onChange={(e) => setAuthForm({ ...authForm, password: e.target.value })}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  style={{
                    position: 'absolute',
                    right: '10px',
                    top: '50%',
                    transform: 'translateY(-50%)',
                    background: 'none',
                    border: 'none',
                    color: '#888',
                    cursor: 'pointer',
                    fontSize: '0.8rem',
                    fontWeight: 'bold'
                  }}
                >
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>

            {authError && <div style={{ color: 'var(--color-error)', fontSize: '0.85rem', marginBottom: '1.5rem', textAlign: 'left' }}>{authError}</div>}

            <button type="submit" className="form-button" disabled={authLoading}>
              {authLoading ? 'Authenticating...' : 'Log In'}
            </button>
          </form>

          
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
          <span className="brand-logo" style={{display: "none"}}></span>
          <span className="brand-title">777 UGI</span>
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
              {activeTab === 'dashboard' && ''}
              {activeTab === 'deposits' && 'Verify blockchain confirmations & trigger payouts'}
              {activeTab === 'agents' && 'Manage agent accounts, payout details, and referred sellers'}
              {activeTab === 'rates' && 'Lock live USDT to INR exchange buy rates'}
              {activeTab === 'settings' && 'Configure 4-chain gateway deposit wallets & QR codes'}
              {activeTab === 'logs' && 'Security records of admin commands logged'}
            </p>
          </div>

          <div className="header-actions">
            
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
        {activeTab === 'agents' && (() => {
          const filteredAgents = agents.filter(agent => {
            if (!referralAgentSearchQuery.trim()) return true;
            const q = referralAgentSearchQuery.trim().toLowerCase();
            const name = (agent.name || '').toLowerCase();
            const code = (agent.referralCode || '').toLowerCase();
            const email = (agent.email || '').toLowerCase();
            const phone = (agent.phone || '').toLowerCase();
            return name.includes(q) || code.includes(q) || email.includes(q) || phone.includes(q);
          });

          return (
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

            {/* Search Bar for Referral Agents */}
            <div className="dashboard-card" style={{ padding: '0.85rem 1.25rem', background: 'rgba(15, 23, 42, 0.75)', border: '1px solid rgba(0, 242, 254, 0.25)' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '1rem', flexWrap: 'wrap' }}>
                <div style={{ position: 'relative', flex: 1, minWidth: '280px' }}>
                  <span style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', opacity: 0.6, fontSize: '1rem', pointerEvents: 'none' }}>
                    🔍
                  </span>
                  <input
                    type="text"
                    className="form-input"
                    placeholder="Search agents by Name, Referral Code (e.g. AGENT001), Email or Phone..."
                    value={referralAgentSearchQuery}
                    onChange={(e) => setReferralAgentSearchQuery(e.target.value)}
                    style={{
                      paddingLeft: '2.75rem',
                      paddingRight: referralAgentSearchQuery ? '2.5rem' : '1rem',
                      width: '100%',
                      background: 'rgba(255, 255, 255, 0.04)',
                      border: '1px solid rgba(0, 242, 254, 0.25)',
                      borderRadius: '10px',
                      fontSize: '0.9rem',
                      color: 'var(--text-color)'
                    }}
                  />
                  {referralAgentSearchQuery && (
                    <button
                      type="button"
                      onClick={() => setReferralAgentSearchQuery('')}
                      style={{
                        position: 'absolute',
                        right: '0.75rem',
                        top: '50%',
                        transform: 'translateY(-50%)',
                        background: 'rgba(255, 255, 255, 0.1)',
                        border: 'none',
                        color: 'var(--text-muted)',
                        borderRadius: '50%',
                        width: '22px',
                        height: '22px',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: '0.75rem'
                      }}
                      title="Clear search"
                    >
                      ✕
                    </button>
                  )}
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.85rem', color: 'var(--text-muted)' }}>
                  <span>
                    Showing <strong style={{ color: 'var(--accent-cyan)' }}>{filteredAgents.length}</strong> of <strong style={{ color: 'var(--text-color)' }}>{agents.length}</strong> agents
                  </span>
                  {referralAgentSearchQuery && (
                    <button
                      className="btn btn-secondary"
                      onClick={() => setReferralAgentSearchQuery('')}
                      style={{ padding: '0.35rem 0.75rem', fontSize: '0.75rem' }}
                    >
                      Reset Filter
                    </button>
                  )}
                </div>
              </div>
            </div>

            <div className="dashboard-card" style={{ padding: 0, overflow: 'hidden' }}>
              <div className="table-responsive">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Agent Info</th>
                      <th>Contact</th>
                      <th>Referral Code</th>
                      <th>Sellers</th>
                      <th>Total Earned</th>
                      <th>Commission</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredAgents.map((agent) => (
                      <tr key={agent.id}>
                        <td>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                            <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: 'rgba(0, 242, 254, 0.12)', color: 'var(--accent-cyan)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.95rem', fontWeight: 'bold', border: '1px solid rgba(0, 242, 254, 0.25)' }}>
                              {agent.name ? agent.name.charAt(0).toUpperCase() : '🤝'}
                            </div>
                            <div>
                              <div style={{ fontWeight: 'bold', fontSize: '0.95rem' }}>{agent.name}</div>
                              <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>ID: {agent.id?.slice(-6) || 'N/A'}</div>
                            </div>
                          </div>
                        </td>
                        <td>
                          <div style={{ fontSize: '0.85rem' }}>{agent.email}</div>
                          <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{agent.phone || 'No phone'}</div>
                        </td>
                        <td>
                          <span style={{ fontFamily: 'monospace', fontWeight: 'bold', color: 'var(--accent-purple)', background: 'rgba(177, 75, 244, 0.1)', padding: '0.2rem 0.5rem', borderRadius: '4px' }}>
                            {agent.referralCode || 'N/A'}
                          </span>
                        </td>
                        <td>
                          <span className="badge badge-verified">{agent.referredSellers?.length || 0}</span>
                        </td>
                        <td>
                          <span style={{ fontWeight: 'bold', color: 'var(--color-success)' }}>
                            ₹{agent.totalEarned?.toLocaleString(undefined, { minimumFractionDigits: 2 }) || '0.00'}
                          </span>
                        </td>
                        <td>
                          <span style={{ fontWeight: 'bold', color: 'var(--accent-cyan)' }}>{agent.commissionPercent}%</span>
                        </td>
                        <td>
                          <button
                            className="btn-action-view"
                            onClick={() => { setSelectedAgentDetail(agent); setShowAgentPassword(false); setIsEditingPassword(false); }}
                            title="View complete partner performance, adjust rate & manage deboarding"
                          >
                            <span>👁️</span> View Details ➔
                          </button>
                        </td>
                      </tr>
                    ))}
                    {filteredAgents.length === 0 && (
                      <tr>
                        <td colSpan="7" style={{ textAlign: 'center', padding: '3rem', color: 'var(--text-dimmed)' }}>
                          {referralAgentSearchQuery ? (
                            <div>
                              <div style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>🔍</div>
                              <div style={{ fontSize: '1rem', fontWeight: '600', color: 'var(--text-muted)' }}>
                                No referral partner agents matching "{referralAgentSearchQuery}"
                              </div>
                              <button
                                className="btn btn-secondary"
                                onClick={() => setReferralAgentSearchQuery('')}
                                style={{ marginTop: '0.75rem', padding: '0.4rem 1rem', fontSize: '0.8rem' }}
                              >
                                Clear Search
                              </button>
                            </div>
                          ) : (
                            'No referral partner agents registered yet.'
                          )}
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        );
        })()}

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

        {/* Tab Page: System Configuration Remastered */}
        {activeTab === 'settings' && (
          <div className="system-config-container">
            {/* Executive Status Banner */}
            <div className="config-header-banner">
              <div>
                <h2 className="config-banner-title">
                  <span>⚙️</span> System Engine & Gateway Control Hub
                </h2>
                <p className="config-banner-subtitle">
                  Configure live OTC buy/sell spreads, multi-channel Telegram support desks, multi-chain deposit vaults, and partner routing.
                </p>
              </div>
              <div className="config-status-pills">
                <span className="status-pill">
                  <span className="status-pill-pulse" /> Realtime Sync Active
                </span>
                <span className="status-pill" style={{ color: 'var(--accent-cyan)' }}>
                  ⚡ API Port: 5001 Live
                </span>
                <span className="status-pill" style={{ color: '#38bdf8' }}>
                  ✈️ Dual Telegram Desks: Online
                </span>
              </div>
            </div>

            {/* Remastered 2-Column Grid */}
            <div className="config-remaster-grid">
              
              {/* CARD 1: OFFICIAL TELEGRAM SUPPORT ROUTING HUB (AGENTS & SELLERS) */}
              <div className="config-card-premium" style={{ gridColumn: 'span 2' }}>
                <div className="config-card-header">
                  <div>
                    <h3 className="config-card-title">
                      <span style={{ fontSize: '1.4rem' }}>🎧</span> Official Telegram Support Desk & Request Routing
                    </h3>
                    <p className="config-card-desc">
                      Configure dedicated Telegram bots/channels to listen to and handle live requests from both <strong>Sellers</strong> and <strong>Referral Agents</strong>.
                    </p>
                  </div>
                  <span className="badge badge-verified" style={{ background: 'rgba(14, 165, 233, 0.15)', color: '#38bdf8', border: '1px solid rgba(14, 165, 233, 0.4)' }}>
                    ✈️ Live Telegram Routing
                  </span>
                </div>

                <form onSubmit={handleUpdateSupportConfig}>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '1.25rem', marginBottom: '1.25rem' }}>
                    
                    {/* Seller Support Field */}
                    <div className="telegram-hub-box">
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <label className="form-label" style={{ fontWeight: 'bold', color: 'var(--accent-cyan)', margin: 0 }}>
                          🛒 Seller App Support Desk (Bot / Link)
                        </label>
                        <span className="badge" style={{ fontSize: '0.65rem', background: 'rgba(0, 242, 254, 0.1)', color: 'var(--accent-cyan)' }}>For Sellers</span>
                      </div>
                      <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)', margin: 0 }}>
                        Sellers tapping <em>"Contact Support"</em> or <em>"Help"</em> inside the 777 Seller App will be redirected directly to this Telegram handle.
                      </p>
                      <div className="telegram-input-row">
                        <div className="telegram-input-wrapper">
                          <span className="telegram-icon-prefix">✈️</span>
                          <input
                            className="telegram-input"
                            type="text"
                            placeholder="https://t.me/G_777_bot or @G_777_bot"
                            value={supportTelegramSeller}
                            onChange={(e) => setSupportTelegramSeller(e.target.value)}
                            required
                          />
                        </div>
                        <button
                          type="button"
                          className="btn-telegram-test"
                          onClick={() => handleTestOpenTelegram(supportTelegramSeller)}
                          title="Open link in Telegram to test"
                        >
                          🚀 Test Link
                        </button>
                      </div>
                    </div>

                    {/* Agent / Partner Support Field */}
                    <div className="telegram-hub-box" style={{ background: 'rgba(177, 75, 244, 0.04)', borderColor: 'rgba(177, 75, 244, 0.25)' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <label className="form-label" style={{ fontWeight: 'bold', color: 'var(--accent-purple)', margin: 0 }}>
                          🤝 Referral Agent Priority Desk (VIP Channel)
                        </label>
                        <span className="badge" style={{ fontSize: '0.65rem', background: 'rgba(177, 75, 244, 0.15)', color: 'var(--accent-purple)' }}>For Agents</span>
                      </div>
                      <p style={{ fontSize: '0.78rem', color: 'var(--text-muted)', margin: 0 }}>
                        Referral partner agents can submit commission claims, KYC queries, or banking settlement requests directly to this priority channel.
                      </p>
                      <div className="telegram-input-row">
                        <div className="telegram-input-wrapper">
                          <span className="telegram-icon-prefix">✈️</span>
                          <input
                            className="telegram-input"
                            style={{ borderColor: 'rgba(177, 75, 244, 0.4)' }}
                            type="text"
                            placeholder="https://t.me/G_777_agent_desk or @G_777_agent_desk"
                            value={supportTelegramAgent}
                            onChange={(e) => setSupportTelegramAgent(e.target.value)}
                            required
                          />
                        </div>
                        <button
                          type="button"
                          className="btn-telegram-test"
                          style={{ background: 'linear-gradient(135deg, #9333ea 0%, #7e22ce 100%)' }}
                          onClick={() => handleTestOpenTelegram(supportTelegramAgent)}
                          title="Open link in Telegram to test"
                        >
                          🚀 Test Link
                        </button>
                      </div>
                    </div>
                  </div>

                  {/* Operational Status Notice & Community Link */}
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1rem', marginBottom: '1.25rem' }}>
                    <div className="form-group">
                      <label className="form-label">Support Working Hours / Live Status Notice</label>
                      <input
                        className="form-input"
                        type="text"
                        placeholder="e.g. 24x7 Official Telegram Support Desk Active"
                        value={supportNotice}
                        onChange={(e) => setSupportNotice(e.target.value)}
                      />
                    </div>
                    <div className="form-group">
                      <label className="form-label">General Community / Announcements Channel Link</label>
                      <div className="telegram-input-row">
                        <input
                          className="form-input"
                          type="text"
                          placeholder="https://t.me/ugi777_official"
                          value={telegramLink}
                          onChange={(e) => setTelegramLink(e.target.value)}
                        />
                        <button
                          type="button"
                          className="btn btn-secondary btn-sm"
                          onClick={() => handleTestOpenTelegram(telegramLink)}
                        >
                          Test
                        </button>
                      </div>
                    </div>
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '1rem' }}>
                    <button type="submit" className="btn btn-primary" style={{ padding: '0.75rem 2rem' }} disabled={actionLoading}>
                      {actionLoading ? 'Saving Desk Config...' : '💾 Save Support Routing Channels'}
                    </button>
                  </div>
                </form>
              </div>

              {/* CARD 2: LIVE OTC RATES & MARGIN SPREAD ENGINE */}
              <div className="config-card-premium">
                <div className="config-card-header">
                  <div>
                    <h3 className="config-card-title">
                      <span>📈</span> Live OTC Rates & Margin Spread
                    </h3>
                    <p className="config-card-desc">
                      Set live Indian Rupee (INR) exchange rates for buying and selling USDT.
                    </p>
                  </div>
                  <span className="badge badge-verified">Live Rates</span>
                </div>

                {/* Profit Margin Spread Live Preview Box */}
                {(() => {
                  const buy = parseFloat(exchangeRate) || 0;
                  const sell = parseFloat(sellingRate) || (buy + 1.0);
                  const spread = (sell - buy).toFixed(2);
                  return (
                    <div className="spread-indicator-box">
                      <div>
                        <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', display: 'block' }}>Calculated Platform Margin</span>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.2rem' }}>
                          <span className="spread-pill">
                            💰 Gross Spread: ₹{spread} / USDT
                          </span>
                        </div>
                      </div>
                      <div style={{ textAlign: 'right' }}>
                        <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', display: 'block' }}>Estimated 10,000 USDT Turnover</span>
                        <span style={{ fontSize: '0.9rem', fontWeight: 'bold', color: 'var(--accent-cyan)' }}>
                          ₹{(buy * 10000).toLocaleString(undefined, { minimumFractionDigits: 2 })}
                        </span>
                      </div>
                    </div>
                  );
                })()}

                <form onSubmit={handleUpdateExchangeRate} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                  <div className="form-group">
                    <label className="form-label" style={{ color: 'var(--accent-cyan)' }}>
                      Buying Rate from Sellers (₹ Per USDT)
                    </label>
                    <input
                      className="form-input"
                      type="number"
                      step="0.01"
                      value={exchangeRate}
                      onChange={(e) => setExchangeRate(e.target.value)}
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label" style={{ color: 'var(--accent-purple)' }}>
                      Selling / Benchmark Rate for Partners (₹ Per USDT)
                    </label>
                    <input
                      className="form-input"
                      type="number"
                      step="0.01"
                      value={sellingRate}
                      onChange={(e) => setSellingRate(e.target.value)}
                      placeholder="e.g. 93.50"
                    />
                  </div>

                  <button type="submit" className="btn btn-primary" style={{ width: '100%', marginTop: '0.5rem' }} disabled={actionLoading}>
                    {actionLoading ? 'Updating...' : '🔒 Update Live Exchange Rates'}
                  </button>
                </form>
              </div>

              {/* CARD 3: DEFAULT PARTNER AGENT ROUTING */}
              <div className="config-card-premium">
                <div className="config-card-header">
                  <div>
                    <h3 className="config-card-title">
                      <span>🎯</span> Default Partner Agent Routing
                    </h3>
                    <p className="config-card-desc">
                      Assign default partner agent when new sellers sign up without an invite code.
                    </p>
                  </div>
                  <span className="badge badge-verified">Partner Routing</span>
                </div>

                <form onSubmit={handleUpdateDefaultAgent} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                  
                  {/* Current Active Default Agent Banner */}
                  {(() => {
                    const assigned = agents.find(a => String(a.id || a._id) === String(defaultAgentId));
                    if (assigned) {
                      return (
                        <div style={{
                          background: 'linear-gradient(135deg, rgba(0, 230, 118, 0.08), rgba(0, 242, 254, 0.04))',
                          border: '1px solid rgba(0, 230, 118, 0.35)',
                          borderRadius: '12px',
                          padding: '1rem',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          gap: '12px'
                        }}>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                            <div style={{
                              width: '42px',
                              height: '42px',
                              borderRadius: '50%',
                              background: 'linear-gradient(135deg, #00e676, #00f2fe)',
                              color: '#020617',
                              fontWeight: 'bold',
                              fontSize: '1.1rem',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              boxShadow: '0 0 12px rgba(0, 230, 118, 0.4)'
                            }}>
                              {(assigned.name || 'A').slice(0, 2).toUpperCase()}
                            </div>
                            <div>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                <span style={{ fontWeight: '700', color: '#fff', fontSize: '0.95rem' }}>{assigned.name}</span>
                                <span style={{
                                  background: 'rgba(0, 230, 118, 0.2)',
                                  color: '#00e676',
                                  fontSize: '0.7rem',
                                  fontWeight: '800',
                                  padding: '2px 8px',
                                  borderRadius: '6px',
                                  border: '1px solid rgba(0, 230, 118, 0.4)'
                                }}>
                                  ACTIVE DEFAULT
                                </span>
                              </div>
                              <div style={{ color: 'var(--text-muted)', fontSize: '0.78rem', marginTop: '2px' }}>
                                Code: <strong style={{ color: 'var(--accent-purple)', fontFamily: 'monospace' }}>{assigned.referralCode}</strong> | Cut: <strong style={{ color: '#00e676' }}>{assigned.commissionPercent || 0.5}%</strong> | Phone: {assigned.phone || assigned.email}
                              </div>
                            </div>
                          </div>
                        </div>
                      );
                    }
                    return (
                      <div style={{
                        background: 'rgba(239, 68, 68, 0.08)',
                        border: '1px solid rgba(239, 68, 68, 0.3)',
                        borderRadius: '12px',
                        padding: '0.85rem 1rem',
                        fontSize: '0.82rem',
                        color: '#fca5a5'
                      }}>
                        ⚠️ <strong>No Default Agent Selected.</strong> Search and choose an agent below.
                      </div>
                    );
                  })()}

                  {/* Search Bar for Thousands of Agents */}
                  <div className="form-group" style={{ marginBottom: '0.25rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.4rem' }}>
                      <label className="form-label" style={{ marginBottom: 0, fontSize: '0.85rem' }}>
                        Search & Select Agent ({agents.length} Registered)
                      </label>
                      {agentSearchQuery && (
                        <button
                          type="button"
                          onClick={() => setAgentSearchQuery('')}
                          style={{
                            background: 'none',
                            border: 'none',
                            color: 'var(--accent-cyan)',
                            fontSize: '0.75rem',
                            cursor: 'pointer',
                            textDecoration: 'underline'
                          }}
                        >
                          Clear search
                        </button>
                      )}
                    </div>
                    <div style={{ position: 'relative' }}>
                      <span style={{
                        position: 'absolute',
                        left: '12px',
                        top: '50%',
                        transform: 'translateY(-50%)',
                        fontSize: '1rem',
                        pointerEvents: 'none',
                        opacity: 0.6
                      }}>
                        🔍
                      </span>
                      <input
                        className="form-input"
                        type="text"
                        value={agentSearchQuery}
                        onChange={(e) => setAgentSearchQuery(e.target.value)}
                        placeholder="Search by agent name, code (e.g. AGENT001), phone, or email..."
                        style={{
                          paddingLeft: '38px',
                          background: 'rgba(15, 23, 42, 0.85)',
                          borderColor: agentSearchQuery ? 'var(--accent-cyan)' : 'var(--border-color)',
                          fontSize: '0.88rem'
                        }}
                      />
                    </div>
                  </div>

                  {/* Scrollable Agent Selection Cards */}
                  <div style={{
                    maxHeight: '230px',
                    overflowY: 'auto',
                    border: '1px solid rgba(255, 255, 255, 0.08)',
                    borderRadius: '10px',
                    background: 'rgba(11, 19, 38, 0.6)',
                    padding: '6px',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '6px'
                  }}>
                    {(() => {
                      const query = agentSearchQuery.toLowerCase().trim();
                      const filtered = agents.filter(a => {
                        if (!query) return true;
                        return (
                          (a.name && a.name.toLowerCase().includes(query)) ||
                          (a.referralCode && a.referralCode.toLowerCase().includes(query)) ||
                          (a.phone && a.phone.toLowerCase().includes(query)) ||
                          (a.email && a.email.toLowerCase().includes(query)) ||
                          (String(a.id || a._id).toLowerCase().includes(query))
                        );
                      });

                      if (filtered.length === 0) {
                        return (
                          <div style={{ textAlign: 'center', padding: '1.5rem', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                            {agents.length === 0 ? 'Loading agents from server...' : `No agents found matching "${agentSearchQuery}"`}
                          </div>
                        );
                      }

                      return filtered.map(a => {
                        const aId = String(a.id || a._id);
                        const isSelected = String(defaultAgentId) === aId;

                        return (
                          <div
                            key={aId}
                            onClick={() => setDefaultAgentId(aId)}
                            style={{
                              padding: '10px 14px',
                              borderRadius: '8px',
                              background: isSelected ? 'rgba(0, 242, 254, 0.12)' : 'rgba(255, 255, 255, 0.02)',
                              border: isSelected ? '1px solid #00f2fe' : '1px solid rgba(255, 255, 255, 0.05)',
                              cursor: 'pointer',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'space-between',
                              gap: '10px',
                              transition: 'all 0.15s ease'
                            }}
                            onMouseEnter={(e) => {
                              if (!isSelected) e.currentTarget.style.background = 'rgba(255, 255, 255, 0.06)';
                            }}
                            onMouseLeave={(e) => {
                              if (!isSelected) e.currentTarget.style.background = 'rgba(255, 255, 255, 0.02)';
                            }}
                          >
                            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                              <div style={{
                                width: '18px',
                                height: '18px',
                                borderRadius: '50%',
                                border: isSelected ? '5px solid #00f2fe' : '2px solid rgba(255, 255, 255, 0.3)',
                                background: isSelected ? '#fff' : 'transparent',
                                transition: 'all 0.15s ease'
                              }} />
                              <div>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                  <span style={{ fontWeight: '600', color: isSelected ? '#00f2fe' : '#fff', fontSize: '0.88rem' }}>
                                    {a.name}
                                  </span>
                                  <span style={{
                                    fontFamily: 'monospace',
                                    fontSize: '0.72rem',
                                    fontWeight: 'bold',
                                    background: 'rgba(168, 85, 247, 0.15)',
                                    color: '#c084fc',
                                    padding: '1px 6px',
                                    borderRadius: '4px',
                                    border: '1px solid rgba(168, 85, 247, 0.3)'
                                  }}>
                                    {a.referralCode || 'NO CODE'}
                                  </span>
                                </div>
                                <div style={{ color: 'var(--text-muted)', fontSize: '0.74rem', marginTop: '2px' }}>
                                  {a.phone || a.email} | Cut: <strong style={{ color: '#00e676' }}>{a.commissionPercent || 0.5}%</strong>
                                </div>
                              </div>
                            </div>

                            <button
                              type="button"
                              onClick={(e) => {
                                e.stopPropagation();
                                setDefaultAgentId(aId);
                              }}
                              style={{
                                background: isSelected ? '#00f2fe' : 'rgba(255, 255, 255, 0.08)',
                                color: isSelected ? '#020617' : '#e2e8f0',
                                border: 'none',
                                padding: '4px 10px',
                                borderRadius: '6px',
                                fontSize: '0.75rem',
                                fontWeight: '700',
                                cursor: 'pointer'
                              }}
                            >
                              {isSelected ? '✓ SELECTED' : 'CHOOSE'}
                            </button>
                          </div>
                        );
                      });
                    })()}
                  </div>

                  <button
                    type="submit"
                    className="btn btn-primary"
                    style={{ width: '100%', marginTop: '0.5rem', fontWeight: 'bold' }}
                    disabled={actionLoading}
                  >
                    {actionLoading ? 'Saving Default Agent...' : '💾 Save Default Partner Agent'}
                  </button>
                </form>
              </div>

              {/* CARD 4: MULTI-CHAIN DEPOSIT VAULTS & DYNAMIC QR CODES */}
              <div className="config-card-premium" style={{ gridColumn: 'span 2' }}>
                <div className="config-card-header">
                  <div>
                    <h3 className="config-card-title">
                      <span>🛡️</span> Multi-Chain Deposit Vaults & Dynamic QR Codes
                    </h3>
                    <p className="config-card-desc">
                      Official deposit addresses for 4 major blockchains. Any updates automatically reflect in real-time inside all Seller Apps!
                    </p>
                  </div>
                  <span className="badge badge-verified">4 Blockchains Active</span>
                </div>

                <form onSubmit={handleUpdateWallets}>
                  <div className="vault-networks-grid">
                    
                    {/* TRC20 (Tron) */}
                    <div className="vault-network-card">
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <span className="network-badge badge-trc20">⚡ Tron (TRC20)</span>
                        <button
                          type="button"
                          className="btn btn-secondary btn-sm"
                          style={{ padding: '0.2rem 0.6rem', fontSize: '0.72rem' }}
                          onClick={() => handleCopyWalletAddress('TRC20', wallets.TRC20)}
                        >
                          {copiedWalletNetwork === 'TRC20' ? '✅ Copied!' : '📋 Copy Address'}
                        </button>
                      </div>
                      <input
                        className="form-input"
                        style={{ fontFamily: 'monospace', fontSize: '0.82rem' }}
                        type="text"
                        placeholder="T..."
                        value={wallets.TRC20 || ''}
                        onChange={(e) => setWallets({ ...wallets, TRC20: e.target.value })}
                        required
                      />
                      {resolveQrUrl(wallets.TRC20, wallets.trc20QrUrl) && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', background: 'rgba(0,0,0,0.2)', padding: '0.5rem', borderRadius: '8px' }}>
                          <img src={resolveQrUrl(wallets.TRC20, wallets.trc20QrUrl)} alt="TRC20 QR" style={{ width: '56px', height: '56px', background: 'white', padding: '2px', borderRadius: '6px' }} />
                          <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>
                            <strong style={{ color: '#f87171', display: 'block' }}>Dynamic TRC20 QR Live</strong>
                            Scannable by Trust Wallet & Binance
                          </div>
                        </div>
                      )}
                    </div>

                    {/* ERC20 (Ethereum) */}
                    <div className="vault-network-card">
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <span className="network-badge badge-erc20">🔷 Ethereum (ERC20)</span>
                        <button
                          type="button"
                          className="btn btn-secondary btn-sm"
                          style={{ padding: '0.2rem 0.6rem', fontSize: '0.72rem' }}
                          onClick={() => handleCopyWalletAddress('ERC20', wallets.ERC20)}
                        >
                          {copiedWalletNetwork === 'ERC20' ? '✅ Copied!' : '📋 Copy Address'}
                        </button>
                      </div>
                      <input
                        className="form-input"
                        style={{ fontFamily: 'monospace', fontSize: '0.82rem' }}
                        type="text"
                        placeholder="0x..."
                        value={wallets.ERC20 || ''}
                        onChange={(e) => setWallets({ ...wallets, ERC20: e.target.value })}
                      />
                      {resolveQrUrl(wallets.ERC20, wallets.erc20QrUrl) && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', background: 'rgba(0,0,0,0.2)', padding: '0.5rem', borderRadius: '8px' }}>
                          <img src={resolveQrUrl(wallets.ERC20, wallets.erc20QrUrl)} alt="ERC20 QR" style={{ width: '56px', height: '56px', background: 'white', padding: '2px', borderRadius: '6px' }} />
                          <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>
                            <strong style={{ color: '#60a5fa', display: 'block' }}>Dynamic ERC20 QR Live</strong>
                            MetaMask & Web3 Compatible
                          </div>
                        </div>
                      )}
                    </div>

                    {/* BEP20 (Binance Smart Chain) */}
                    <div className="vault-network-card">
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <span className="network-badge badge-bep20">🟡 Binance Smart Chain (BEP20)</span>
                        <button
                          type="button"
                          className="btn btn-secondary btn-sm"
                          style={{ padding: '0.2rem 0.6rem', fontSize: '0.72rem' }}
                          onClick={() => handleCopyWalletAddress('BEP20', wallets.BEP20)}
                        >
                          {copiedWalletNetwork === 'BEP20' ? '✅ Copied!' : '📋 Copy Address'}
                        </button>
                      </div>
                      <input
                        className="form-input"
                        style={{ fontFamily: 'monospace', fontSize: '0.82rem' }}
                        type="text"
                        placeholder="0x..."
                        value={wallets.BEP20 || ''}
                        onChange={(e) => setWallets({ ...wallets, BEP20: e.target.value })}
                      />
                      {resolveQrUrl(wallets.BEP20, wallets.bep20QrUrl) && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', background: 'rgba(0,0,0,0.2)', padding: '0.5rem', borderRadius: '8px' }}>
                          <img src={resolveQrUrl(wallets.BEP20, wallets.bep20QrUrl)} alt="BEP20 QR" style={{ width: '56px', height: '56px', background: 'white', padding: '2px', borderRadius: '6px' }} />
                          <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>
                            <strong style={{ color: '#fbbf24', display: 'block' }}>Dynamic BEP20 QR Live</strong>
                            BSC Network Low Fee Deposit
                          </div>
                        </div>
                      )}
                    </div>

                    {/* SOL (Solana) */}
                    <div className="vault-network-card">
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <span className="network-badge badge-sol">🟣 Solana (SOL)</span>
                        <button
                          type="button"
                          className="btn btn-secondary btn-sm"
                          style={{ padding: '0.2rem 0.6rem', fontSize: '0.72rem' }}
                          onClick={() => handleCopyWalletAddress('SOL', wallets.SOL)}
                        >
                          {copiedWalletNetwork === 'SOL' ? '✅ Copied!' : '📋 Copy Address'}
                        </button>
                      </div>
                      <input
                        className="form-input"
                        style={{ fontFamily: 'monospace', fontSize: '0.82rem' }}
                        type="text"
                        placeholder="Solana address..."
                        value={wallets.SOL || ''}
                        onChange={(e) => setWallets({ ...wallets, SOL: e.target.value })}
                      />
                      {resolveQrUrl(wallets.SOL, wallets.solQrUrl) && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', background: 'rgba(0,0,0,0.2)', padding: '0.5rem', borderRadius: '8px' }}>
                          <img src={resolveQrUrl(wallets.SOL, wallets.solQrUrl)} alt="SOL QR" style={{ width: '56px', height: '56px', background: 'white', padding: '2px', borderRadius: '6px' }} />
                          <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>
                            <strong style={{ color: '#c084fc', display: 'block' }}>Dynamic SOL QR Live</strong>
                            Phantom & Solana Pay Compatible
                          </div>
                        </div>
                      )}
                    </div>

                  </div>

                  <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '1.25rem' }}>
                    <button type="submit" className="btn btn-primary" style={{ padding: '0.85rem 2.5rem', fontSize: '0.95rem' }} disabled={actionLoading}>
                      {actionLoading ? 'Saving Wallets...' : '🔒 Save Multi-Chain Vault Parameters'}
                    </button>
                  </div>
                </form>
              </div>

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
                  <div style={{ width: '44px', height: '44px', borderRadius: '12px', background: 'rgba(0, 242, 254, 0.15)', color: 'var(--accent-cyan)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold', fontSize: '1.2rem', border: '1px solid rgba(0, 242, 254, 0.25)' }}>
                    {selectedAgentDetail.name ? selectedAgentDetail.name.charAt(0).toUpperCase() : '🤝'}
                  </div>
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
                            ✅ All profile credentials and bank payout account info are 100% complete and verified.
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

                {/* Agent Account Security & Password Management */}
                <div style={{ background: 'rgba(177, 75, 244, 0.04)', padding: '1.1rem', borderRadius: '12px', border: '1px solid rgba(177, 75, 244, 0.25)' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem', flexWrap: 'wrap', gap: '0.5rem' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <span style={{ fontSize: '1.1rem' }}>🔑</span>
                      <h4 style={{ fontSize: '0.85rem', color: 'var(--accent-purple)', margin: 0, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                        Partner Login Credentials & Password
                      </h4>
                    </div>
                    {!isEditingPassword && (
                      <button
                        type="button"
                        className="btn btn-secondary"
                        onClick={() => {
                          setIsEditingPassword(true);
                          setNewAgentPasswordInput('');
                        }}
                        style={{ padding: '0.35rem 0.75rem', fontSize: '0.75rem', borderColor: 'rgba(177, 75, 244, 0.4)', color: 'var(--accent-purple)' }}
                      >
                        ✏️ Change Password
                      </button>
                    )}
                  </div>

                  {!isEditingPassword ? (
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '0.75rem' }}>
                      <div style={{ background: 'rgba(255, 255, 255, 0.02)', padding: '0.65rem 0.85rem', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
                        <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', display: 'block' }}>Login Email</span>
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: '0.2rem' }}>
                          <span style={{ fontSize: '0.9rem', fontWeight: '600', color: 'var(--text-color)' }}>{selectedAgentDetail.email}</span>
                          <button
                            type="button"
                            onClick={() => {
                              navigator.clipboard.writeText(selectedAgentDetail.email);
                              alert('📋 Email copied to clipboard!');
                            }}
                            style={{ background: 'none', border: 'none', color: 'var(--accent-cyan)', cursor: 'pointer', fontSize: '0.8rem' }}
                            title="Copy Email"
                          >
                            📋
                          </button>
                        </div>
                      </div>

                      <div style={{ background: 'rgba(255, 255, 255, 0.02)', padding: '0.65rem 0.85rem', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
                        <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', display: 'block' }}>Current Password</span>
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: '0.2rem' }}>
                          <span style={{ fontSize: '0.95rem', fontWeight: 'bold', fontFamily: 'monospace', color: showAgentPassword ? '#00e676' : 'var(--text-muted)' }}>
                            {showAgentPassword ? (selectedAgentDetail.password || 'password') : '••••••••••••'}
                          </span>
                          <div style={{ display: 'flex', gap: '0.4rem', alignItems: 'center' }}>
                            <button
                              type="button"
                              onClick={() => setShowAgentPassword(!showAgentPassword)}
                              style={{ background: 'rgba(255,255,255,0.06)', border: 'none', color: 'var(--text-color)', borderRadius: '4px', padding: '0.2rem 0.45rem', cursor: 'pointer', fontSize: '0.75rem' }}
                              title={showAgentPassword ? 'Hide password' : 'View password'}
                            >
                              {showAgentPassword ? '🙈 Hide' : '👁️ View'}
                            </button>
                            <button
                              type="button"
                              onClick={() => {
                                navigator.clipboard.writeText(selectedAgentDetail.password || 'password');
                                alert('📋 Password copied to clipboard!');
                              }}
                              style={{ background: 'rgba(0, 242, 254, 0.1)', border: 'none', color: 'var(--accent-cyan)', borderRadius: '4px', padding: '0.2rem 0.45rem', cursor: 'pointer', fontSize: '0.75rem' }}
                              title="Copy Password"
                            >
                              📋 Copy
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  ) : (
                    <div style={{ background: 'rgba(0, 0, 0, 0.3)', padding: '0.85rem', borderRadius: '8px', border: '1px solid rgba(177, 75, 244, 0.3)' }}>
                      <label className="form-label" style={{ fontSize: '0.75rem', color: 'var(--accent-purple)', marginBottom: '0.4rem' }}>
                        Set New Password for {selectedAgentDetail.name}
                      </label>
                      <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                        <input
                          type="text"
                          className="form-input"
                          placeholder="Enter new password (e.g. Partner@777)"
                          value={newAgentPasswordInput}
                          onChange={(e) => setNewAgentPasswordInput(e.target.value)}
                          style={{ flex: 1, minWidth: '200px', fontSize: '0.9rem', padding: '0.5rem 0.75rem' }}
                        />
                        <button
                          type="button"
                          className="btn btn-secondary"
                          onClick={() => {
                            const gen = 'Partner@' + Math.floor(1000 + Math.random() * 9000);
                            setNewAgentPasswordInput(gen);
                          }}
                          style={{ fontSize: '0.78rem', padding: '0.5rem 0.75rem' }}
                        >
                          ⚡ Auto-Gen
                        </button>
                        <button
                          type="button"
                          className="btn btn-primary"
                          onClick={() => handleUpdateAgentPassword(selectedAgentDetail.id || selectedAgentDetail._id)}
                          disabled={passwordUpdateLoading}
                          style={{ fontSize: '0.78rem', padding: '0.5rem 0.85rem' }}
                        >
                          {passwordUpdateLoading ? 'Saving...' : '💾 Save Password'}
                        </button>
                        <button
                          type="button"
                          className="btn btn-secondary"
                          onClick={() => {
                            setIsEditingPassword(false);
                            setNewAgentPasswordInput('');
                          }}
                          style={{ fontSize: '0.78rem', padding: '0.5rem 0.75rem' }}
                        >
                          Cancel
                        </button>
                      </div>
                    </div>
                  )}
                </div>

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

              <div className="modal-footer" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.75rem' }}>
                <button
                  className="btn-modal-deboard"
                  onClick={() => {
                    const agent = selectedAgentDetail;
                    setSelectedAgentDetail(null);
                    handleDeboardAgent(agent);
                  }}
                  title="Remove this agent and safely reassign their sellers"
                >
                  <span>🚫</span> Deboard Partner Agent
                </button>
                <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
                  <button className="btn btn-secondary" onClick={() => setSelectedAgentDetail(null)}>Close View</button>
                  <button className="btn-modal-rate" onClick={() => {
                    const agent = selectedAgentDetail;
                    setSelectedAgentDetail(null);
                    handleAgentCommission(agent.id || agent._id, agent.commissionPercent);
                  }}>
                    <span>⚙️</span> Adjust Commission Rate
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Deboard Agent Confirmation Modal */}
        {agentToDeboard && (
          <div className="modal-overlay">
            <div className="modal-content" style={{ maxWidth: '520px', borderRadius: '16px', overflow: 'hidden', border: '1px solid rgba(239, 68, 68, 0.4)', boxShadow: '0 25px 50px rgba(0, 0, 0, 0.5), 0 0 30px rgba(239, 68, 68, 0.15)' }}>
              <div className="modal-header" style={{ padding: '1.5rem 1.75rem', borderBottom: '1px solid rgba(239, 68, 68, 0.2)', background: 'rgba(239, 68, 68, 0.05)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                  <span style={{ fontSize: '1.5rem' }}>⚠️</span>
                  <h3 className="modal-title" style={{ color: '#f87171', margin: 0 }}>Confirm Agent Deboarding</h3>
                </div>
                <button className="modal-close" onClick={() => setAgentToDeboard(null)}>×</button>
              </div>

              <div className="modal-body" style={{ padding: '1.75rem', display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                <p style={{ margin: 0, fontSize: '0.95rem', color: 'var(--text-main)', lineHeight: '1.6' }}>
                  Are you sure you want to deboard partner agent <strong style={{ color: 'var(--accent-cyan)' }}>{agentToDeboard.name}</strong> from the 777 platform?
                </p>

                <div style={{ background: 'rgba(255, 255, 255, 0.03)', border: '1px solid var(--border-color)', borderRadius: '12px', padding: '1.15rem 1.25rem', display: 'flex', flexDirection: 'column', gap: '0.65rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.85rem' }}>
                    <span style={{ color: 'var(--text-muted)' }}>Referral Code:</span>
                    <strong style={{ fontFamily: 'monospace', color: 'var(--accent-purple)', background: 'rgba(177, 75, 244, 0.12)', padding: '0.2rem 0.6rem', borderRadius: '4px' }}>
                      {agentToDeboard.referralCode || 'N/A'}
                    </strong>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.85rem' }}>
                    <span style={{ color: 'var(--text-muted)' }}>Contact Email:</span>
                    <span style={{ color: 'var(--text-main)' }}>{agentToDeboard.email}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.85rem' }}>
                    <span style={{ color: 'var(--text-muted)' }}>Active Referred Sellers:</span>
                    <span className="badge badge-verified">{agentToDeboard.referredSellers?.length || 0} Sellers</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.85rem' }}>
                    <span style={{ color: 'var(--text-muted)' }}>Total Commission Earned:</span>
                    <strong style={{ color: 'var(--color-success)', fontSize: '0.95rem' }}>
                      ₹{agentToDeboard.totalEarned?.toLocaleString(undefined, { minimumFractionDigits: 2 }) || '0.00'}
                    </strong>
                  </div>
                </div>

                <div style={{ background: 'rgba(239, 68, 68, 0.08)', border: '1px solid rgba(239, 68, 68, 0.25)', borderRadius: '10px', padding: '1rem 1.25rem', fontSize: '0.82rem', color: '#fca5a5', lineHeight: '1.5' }}>
                  <strong style={{ display: 'block', marginBottom: '0.4rem', color: '#f87171' }}>🛡️ System Protection Policy:</strong>
                  <div>• Partner login & referral privileges will be immediately deactivated.</div>
                  <div style={{ marginTop: '0.2rem' }}>• All referred sellers will be automatically reassigned to the default system partner so their trading is never interrupted.</div>
                </div>
              </div>

              <div className="modal-footer" style={{ padding: '1.25rem 1.75rem', background: 'rgba(0, 0, 0, 0.25)', borderTop: '1px solid var(--border-color)', display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
                <button className="btn btn-secondary" onClick={() => setAgentToDeboard(null)} disabled={actionLoading}>
                  Cancel
                </button>
                <button
                  className="btn"
                  style={{ background: 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)', color: 'white', border: 'none', fontWeight: 'bold', padding: '0.65rem 1.4rem', borderRadius: '8px', cursor: 'pointer', boxShadow: '0 4px 14px rgba(239, 68, 68, 0.35)' }}
                  onClick={confirmDeboardAgent}
                  disabled={actionLoading}
                >
                  {actionLoading ? 'Deboarding Agent...' : 'Confirm Deboard 🚫'}
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
                        const copyText = `777 USDT Gateway India - Partner Onboarding Details\n--------------------------------------------------\nWelcome, ${onboardSuccess.name}! You have been onboarded as an Agent/Partner.\n\nCredentials:\nEmail: ${onboardSuccess.email}\nPassword: ${onboardSuccess.password}\n\nReferral Parameters:\nReferral Code: ${onboardSuccess.referralCode}\nCommission Rate: ${onboardSuccess.commissionPercent}%\n\nYou can now log in to the partner app to track your referred sellers and commission.`;
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
