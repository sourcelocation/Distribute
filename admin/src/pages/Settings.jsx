import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { CornerBrackets, GlowBorders } from '../components/FUI';
import { Shield, Key, Server, Save, LogOut, Trash2, Database, RefreshCw } from 'lucide-react';
import { useAuth } from '../AuthContext';
import api from '../api';
import Alert from '../components/Alert';

const SettingsView = () => {
    const { user, logout } = useAuth();
    const navigate = useNavigate();
    const location = useLocation();
    const [activeTab, setActiveTab] = useState(location.state?.activeTab || 'security');

    useEffect(() => {
        if (location.state?.activeTab) {
            setActiveTab(location.state.activeTab);
        }
    }, [location.state?.activeTab]);

    // Security State
    const [password, setPassword] = useState('');
    const [loading, setLoading] = useState(false);
    const [msg, setMsg] = useState('');
    const [msgType, setMsgType] = useState('primary');

    // Maintenance State
    const [cleanupLoading, setCleanupLoading] = useState(false);
    const [reindexLoading, setReindexLoading] = useState(false);

    // General State
    const [generalSettings, setGeneralSettings] = useState({
        server_url: '',
        mail_categories: '',
        request_mail_announcement: ''
    });
    const [generalLoading, setGeneralLoading] = useState(false);

    useEffect(() => {
        if (activeTab === 'general') {
            loadSettings();
        }
    }, [activeTab]);

    const loadSettings = async () => {
        try {
            const res = await api.get('/admin/settings');
            setGeneralSettings(res.data);
        } catch (e) {
            console.error("Failed to load settings", e);
        }
    };

    const handlePasswordChange = async (e) => {
        e.preventDefault();
        setLoading(true);
        setMsg('');
        try {
            await api.put(`/users/${user.id}/password`, { password });
            setMsg('SUCCESS: CREDENTIALS UPDATED');
            setMsgType('primary');
            setPassword('');
        } catch (e) {
            setMsg('ERROR: ' + (e.response?.data?.error || e.message));
            setMsgType('error');
        } finally {
            setLoading(false);
        }
    };

    const handleLogout = () => {
        logout();
        navigate('/login');
    };

    const handleGeneralSave = async (e) => {
        e.preventDefault();
        setGeneralLoading(true);
        try {
            await api.put('/admin/settings', generalSettings);
            setMsg('SUCCESS: SETTINGS SAVED');
            setMsgType('primary');
            setTimeout(() => setMsg(''), 3000);
        } catch (e) {
            setMsg('ERROR: ' + (e.response?.data?.error || e.message));
            setMsgType('error');
        } finally {
            setGeneralLoading(false);
        }
    };

    const handleCleanup = async () => {
        setCleanupLoading(true);
        setMsg('');
        try {
            const res = await api.delete('/admin/orphans');
            const stats = Object.entries(res.data)
                .filter(([_, count]) => count > 0)
                .map(([key, count]) => `${key}: ${count}`)
                .join(', ');

            setMsg(stats ? `CLEANUP COMPLETE: ${stats}` : 'CLEANUP COMPLETE: NO ORPHANS FOUND');
            setMsgType('primary');
        } catch (e) {
            setMsg('ERROR: ' + (e.response?.data?.error || e.message));
            setMsgType('error');
        } finally {
            setCleanupLoading(false);
        }
    };

    const handleReindex = async () => {
        setReindexLoading(true);
        setMsg('');
        try {
            await api.post('/search/reindex');
            setMsg('SUCCESS: SEARCH INDEX REBUILT');
            setMsgType('primary');
        } catch (e) {
            console.error(e);
            setMsg('ERROR: ' + (e.response?.data?.error || e.message));
            setMsgType('error');
        } finally {
            setReindexLoading(false);
        }
    };

    return (
        <main className="flex-1 overflow-y-auto grid-bg p-6 flex flex-col gap-6 animate-slide-in">
            <div>
                <h2 className="text-2xl font-bold text-white tracking-[0.1em] flex items-center gap-3">
                    <Shield className="w-6 h-6 text-primary" /> SETTINGS
                </h2>
                <p className="text-[10px] text-white/40 font-mono mt-1">System configuration and personal security.</p>
            </div>

            <div className="flex gap-4 border-b border-white/5">
                <button
                    onClick={() => setActiveTab('security')}
                    className={`pb-3 px-1 text-xs font-bold tracking-widest transition-colors ${activeTab === 'security' ? 'text-primary border-b-2 border-primary' : 'text-slate-500 hover:text-white'}`}
                >
                    SECURITY
                </button>
                <button
                    onClick={() => setActiveTab('general')}
                    className={`pb-3 px-1 text-xs font-bold tracking-widest transition-colors ${activeTab === 'general' ? 'text-primary border-b-2 border-primary' : 'text-slate-500 hover:text-white'}`}
                >
                    GENERAL
                </button>
                <button
                    onClick={() => setActiveTab('maintenance')}
                    className={`pb-3 px-1 text-xs font-bold tracking-widest transition-colors ${activeTab === 'maintenance' ? 'text-primary border-b-2 border-primary' : 'text-slate-500 hover:text-white'}`}
                >
                    MAINTENANCE
                </button>
            </div>

            <div className="panel p-8 relative max-w-2xl">
                <CornerBrackets />

                <Alert type={msgType} message={msg} />

                {activeTab === 'security' && (
                    <div className="space-y-8 animate-slide-in">
                        <div className="flex items-center gap-4 p-4 bg-white/5 border border-white/10">
                            <div className="w-12 h-12 bg-primary/20 rounded-full flex items-center justify-center">
                                <Key className="w-6 h-6 text-primary" />
                            </div>
                            <div>
                                <h3 className="text-white font-bold text-sm">CHANGE PASSWORD</h3>
                                <p className="text-[10px] text-white/40 font-mono">Ensure a strong password sequence.</p>
                            </div>
                        </div>

                        <form onSubmit={handlePasswordChange} className="space-y-4 max-w-md">
                            <div className="space-y-1">
                                <label className="text-[10px] text-primary font-bold tracking-widest block">NEW PASSCODE</label>
                                <input
                                    type="password"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    className="w-full bg-black/40 border border-white/10 p-3 text-white text-xs focus:border-primary focus:outline-none"
                                    placeholder="••••••••"
                                />
                            </div>

                            <button disabled={loading} className="bg-primary/10 border border-primary/30 text-primary px-6 py-3 font-bold text-xs hover:bg-primary hover:text-black transition-colors flex items-center gap-2 cursor-pointer">
                                <Save className="w-4 h-4" /> {loading ? 'UPDATING...' : 'UPDATE CREDENTIALS'}
                            </button>
                        </form>

                        <div className="pt-8 border-t border-white/10">
                            <button onClick={handleLogout} className="border border-red-500/30 text-red-400 px-6 py-3 font-bold text-xs hover:bg-red-500/10 transition-colors flex items-center gap-2 cursor-pointer">
                                <LogOut className="w-4 h-4" /> LOG OUT SESSION
                            </button>
                        </div>
                    </div>
                )}

                {activeTab === 'general' && (
                    <div className="space-y-8 animate-slide-in">
                        <div className="flex items-center gap-4 p-4 bg-white/5 border border-white/10">
                            <div className="w-12 h-12 bg-secondary/20 rounded-full flex items-center justify-center">
                                <Server className="w-6 h-6 text-secondary" />
                            </div>
                            <div>
                                <h3 className="text-white font-bold text-sm">SERVER CONFIGURATION</h3>
                                <p className="text-[10px] text-white/40 font-mono">Manage instance parameters.</p>
                            </div>
                        </div>

                        <form onSubmit={handleGeneralSave} className="space-y-4">
                            <div className="space-y-1">
                                <label className="text-[10px] text-primary font-bold tracking-widest block">PUBLIC SERVER URL</label>
                                <input
                                    type="text"
                                    value={generalSettings.server_url}
                                    onChange={(e) => setGeneralSettings({ ...generalSettings, server_url: e.target.value })}
                                    className="w-full bg-black/40 border border-white/10 p-3 text-white font-mono text-sm focus:border-primary focus:outline-none"
                                />
                            </div>
                            <div className="space-y-1">
                                <label className="text-[10px] text-primary font-bold tracking-widest block">MAIL CATEGORIES</label>
                                <input
                                    type="text"
                                    value={generalSettings.mail_categories}
                                    onChange={(e) => setGeneralSettings({ ...generalSettings, mail_categories: e.target.value })}
                                    className="w-full bg-black/40 border border-white/10 p-3 text-white font-mono text-sm focus:border-primary focus:outline-none"
                                />
                                <p className="text-[10px] text-white/30 font-mono">Comma separated.</p>
                            </div>
                            <div className="space-y-1">
                                <label className="text-[10px] text-primary font-bold tracking-widest block">ANNOUNCEMENT</label>
                                <textarea
                                    value={generalSettings.request_mail_announcement}
                                    onChange={(e) => setGeneralSettings({ ...generalSettings, request_mail_announcement: e.target.value })}
                                    className="w-full bg-black/40 border border-white/10 p-3 text-white font-mono text-sm focus:border-primary focus:outline-none h-20 resize-none"
                                />
                            </div>

                            <div className="flex justify-between items-center p-4 border border-white/5">
                                <div>
                                    <h4 className="text-white text-xs font-bold">DEBUG LOGGING</h4>
                                    <p className="text-[10px] text-white/30">Verbose output in server logs.</p>
                                </div>
                                <div className="w-10 h-5 bg-white/10 rounded-full relative cursor-pointer">
                                    <div className="absolute left-1 top-1 w-3 h-3 bg-white/40 rounded-full"></div>
                                </div>
                            </div>

                            <button disabled={generalLoading} className="bg-primary/10 border border-primary/30 text-primary px-6 py-3 font-bold text-xs hover:bg-primary hover:text-black transition-colors flex items-center gap-2 cursor-pointer">
                                <Save className="w-4 h-4" /> {generalLoading ? 'SAVING...' : 'SAVE CONFIGURATION'}
                            </button>
                        </form>
                    </div>
                )}

                {activeTab === 'maintenance' && (
                    <div className="space-y-8 animate-slide-in">
                        <div className="flex items-center gap-4 p-4 bg-white/5 border border-white/10">
                            <div className="w-12 h-12 bg-red-500/20 rounded-full flex items-center justify-center">
                                <Database className="w-6 h-6 text-red-500" />
                            </div>
                            <div>
                                <h3 className="text-white font-bold text-sm">SYSTEM MAINTENANCE</h3>
                                <p className="text-[10px] text-white/40 font-mono">Manage database integrity.</p>
                            </div>
                        </div>

                        <div className="p-4 border border-white/5 bg-black/40">
                            <h4 className="text-white text-xs font-bold mb-2">ORPHAN CLEANUP</h4>
                            <p className="text-[10px] text-white/40 font-mono mb-4">
                                Remove songs, albums, and artists that are no longer referenced or consistent.
                                This action is irreversible.
                            </p>

                            <button
                                onClick={handleCleanup}
                                disabled={cleanupLoading}
                                className="bg-red-500/10 border border-red-500/30 text-red-500 px-6 py-3 font-bold text-xs hover:bg-red-500 hover:text-black transition-colors flex items-center gap-2 cursor-pointer"
                            >
                                <Trash2 className="w-4 h-4" /> {cleanupLoading ? 'CLEANING...' : 'CLEANUP'}
                            </button>
                        </div>

                        <div className="p-4 border border-white/5 bg-black/40">
                            <h4 className="text-white text-xs font-bold mb-2">SEARCH INDEX REBUILD</h4>
                            <p className="text-[10px] text-white/40 font-mono mb-4">
                                Re-index all content (Songs, Albums, Artists) to Meilisearch.
                                Safe to run if search results are missing or incorrect.
                            </p>

                            <button
                                onClick={handleReindex}
                                disabled={reindexLoading}
                                className="bg-primary/10 border border-primary/30 text-primary px-6 py-3 font-bold text-xs hover:bg-primary hover:text-black transition-colors flex items-center gap-2 cursor-pointer"
                            >
                                <RefreshCw className={`w-4 h-4 ${reindexLoading ? 'animate-spin' : ''}`} /> {reindexLoading ? 'REINDEXING...' : 'REINDEX ALL'}
                            </button>
                        </div>
                    </div>
                )}
            </div>
        </main>
    );
}

export default SettingsView;
