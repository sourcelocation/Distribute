import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { CornerBrackets, GlowBorders } from '../components/FUI';
import { Shield, Key, Server, Save, LogOut, Trash2, Database, RefreshCw, Wrench, Music } from 'lucide-react';
import { useAuth } from '../AuthContext';
import api from '../api';
import Alert from '../components/Alert';
import { Button } from '../components/ui/button';

const parseBitrates = (raw) => raw
    .split(/[,\s]+/)
    .map((v) => parseInt(v, 10))
    .filter((v) => Number.isFinite(v) && v > 0);

const buildDefaultProfiles = (bitrates) => ([
    {
        variant: 'lossless',
        label: 'Lossless',
        format: 'ogg',
        codec: 'flac',
        bitrate_kbps: 0,
        lossless: true,
    },
    ...bitrates.sort((a, b) => a - b).map((bitrate) => ({
        variant: `${bitrate}k`,
        label: `${bitrate}kbps`,
        format: 'ogg',
        codec: 'libvorbis',
        bitrate_kbps: bitrate,
        lossless: false,
    })),
]);

const normalizeProfiles = (profiles) => {
    if (!Array.isArray(profiles)) return [];
    return profiles.map((profile) => {
        const bitrate = Number(profile.bitrate_kbps ?? profile.bitrate ?? 0) || 0;
        const lossless = profile.lossless === true || bitrate <= 0;
        const format = (profile.format || '').toString().trim().toLowerCase();
        const codec = (profile.codec || '').toString().trim().toLowerCase();
        let variant = (profile.variant || profile.id || '').toString().trim();
        if (!variant) {
            variant = lossless ? 'lossless' : `${bitrate}k`;
        }
        const label = (profile.label || '').toString().trim()
            || (lossless ? 'Lossless' : `${bitrate}kbps`);
        return {
            variant,
            label,
            format: format || 'ogg',
            codec: codec || (lossless ? 'flac' : 'libvorbis'),
            bitrate_kbps: lossless ? 0 : bitrate,
            lossless,
        };
    }).filter((profile) => profile.variant && profile.codec && profile.format);
};

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
    const [doctorLoading, setDoctorLoading] = useState(false);
    const [migrationStatus, setMigrationStatus] = useState(null);
    const [migrationLoading, setMigrationLoading] = useState(false);
    const [migrationRetryLoading, setMigrationRetryLoading] = useState(false);

    // General State
    const [generalSettings, setGeneralSettings] = useState({
        server_url: '',
        mail_categories: '',
        request_mail_announcement: ''
    });
    const [generalLoading, setGeneralLoading] = useState(false);

    // Transcoding State
    const [transcodeSettings, setTranscodeSettings] = useState({
        profiles: []
    });
    const [transcodeLoading, setTranscodeLoading] = useState(false);
    const [backfillLoading, setBackfillLoading] = useState(false);

    useEffect(() => {
        if (activeTab === 'general' || activeTab === 'transcoding') {
            loadSettings();
        }
        if (activeTab === 'maintenance') {
            loadMigrationStatus();
        }
    }, [activeTab]);

    const loadSettings = async () => {
        try {
            const res = await api.get('/admin/settings');
            const data = res.data || {};
            setGeneralSettings(data);
            const rawProfiles = data.transcode_profiles;
            if (rawProfiles && rawProfiles.trim().length > 0) {
                try {
                    const parsed = JSON.parse(rawProfiles);
                    if (Array.isArray(parsed)) {
                        setTranscodeSettings({ profiles: normalizeProfiles(parsed) });
                        return;
                    }
                } catch (e) {
                    console.error('Failed to parse transcode profiles', e);
                }
            }
            const rawBitrates = data.transcode_bitrates;
            if (rawBitrates && rawBitrates.trim().length > 0) {
                setTranscodeSettings({
                    profiles: buildDefaultProfiles(parseBitrates(rawBitrates)),
                });
                return;
            }
            const legacy = [];
            const enable160 = data.transcode_160_enabled
                ? data.transcode_160_enabled === 'true'
                : true;
            const enable320 = data.transcode_320_enabled
                ? data.transcode_320_enabled === 'true'
                : false;
            if (enable160) legacy.push(160);
            if (enable320) legacy.push(320);
            setTranscodeSettings({
                profiles: buildDefaultProfiles(legacy.length > 0 ? legacy : [160]),
            });
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

    const handleTranscodeSave = async (e) => {
        e.preventDefault();
        setTranscodeLoading(true);
        try {
            const payload = normalizeProfiles(transcodeSettings.profiles);
            await api.put('/admin/settings', {
                transcode_profiles: JSON.stringify(payload),
            });
            setMsg('SUCCESS: TRANSCODE SETTINGS SAVED');
            setMsgType('primary');
            setTimeout(() => setMsg(''), 3000);
        } catch (e) {
            setMsg('ERROR: ' + (e.response?.data?.error || e.message));
            setMsgType('error');
        } finally {
            setTranscodeLoading(false);
        }
    };

    const handleBackfill = async () => {
        setBackfillLoading(true);
        setMsg('');
        try {
            const res = await api.post('/admin/transcode/backfill');
            const stats = res.data
                ? `PROCESSED: ${res.data.processed}, CREATED: ${res.data.created}, SKIPPED: ${res.data.skipped}`
                : 'BACKFILL COMPLETE';
            setMsg(stats);
            setMsgType('primary');
        } catch (e) {
            setMsg('ERROR: ' + (e.response?.data?.error || e.message));
            setMsgType('error');
        } finally {
            setBackfillLoading(false);
        }
    };

    const updateProfile = (index, patch) => {
        setTranscodeSettings((prev) => ({
            ...prev,
            profiles: prev.profiles.map((p, i) => (i === index ? { ...p, ...patch } : p)),
        }));
    };

    const addProfile = () => {
        setTranscodeSettings((prev) => ({
            ...prev,
            profiles: [
                ...prev.profiles,
                {
                    variant: '',
                    label: '',
                    format: 'ogg',
                    codec: 'libvorbis',
                    bitrate_kbps: 160,
                    lossless: false,
                },
            ],
        }));
    };

    const removeProfile = (index) => {
        setTranscodeSettings((prev) => ({
            ...prev,
            profiles: prev.profiles.filter((_, i) => i !== index),
        }));
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

    const handleDoctor = async () => {
        setDoctorLoading(true);
        setMsg('');
        try {
            await api.post('/doctor');
            setMsg('SUCCESS: MAINTENANCE TASKS COMPLETE');
            setMsgType('primary');
        } catch (e) {
            console.error(e);
            setMsg('ERROR: ' + (e.response?.data?.error || e.message));
            setMsgType('error');
        } finally {
            setDoctorLoading(false);
        }
    };

    const loadMigrationStatus = async () => {
        setMigrationLoading(true);
        try {
            const res = await api.get('/admin/migrations/status');
            setMigrationStatus(res.data);
        } catch (e) {
            console.error("Failed to load migration status", e);
        } finally {
            setMigrationLoading(false);
        }
    };

    const handleRetryMigrations = async () => {
        setMigrationRetryLoading(true);
        setMsg('');
        try {
            await api.post('/admin/migrations/retry');
            setMsg('MIGRATIONS RESTARTED');
            setMsgType('primary');
            await loadMigrationStatus();
        } catch (e) {
            setMsg('ERROR: ' + (e.response?.data?.error || e.message));
            setMsgType('error');
        } finally {
            setMigrationRetryLoading(false);
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
                    onClick={() => setActiveTab('transcoding')}
                    className={`pb-3 px-1 text-xs font-bold tracking-widest transition-colors ${activeTab === 'transcoding' ? 'text-primary border-b-2 border-primary' : 'text-slate-500 hover:text-white'}`}
                >
                    TRANSCODING
                </button>
                <button
                    onClick={() => setActiveTab('maintenance')}
                    className={`pb-3 px-1 text-xs font-bold tracking-widest transition-colors ${activeTab === 'maintenance' ? 'text-primary border-b-2 border-primary' : 'text-slate-500 hover:text-white'}`}
                >
                    MAINTENANCE
                </button>
            </div>

            <div className={`panel p-8 relative ${activeTab === 'transcoding' ? 'w-full max-w-none' : 'max-w-2xl'}`}>
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

                {activeTab === 'transcoding' && (
                    <div className="space-y-8 animate-slide-in">
                        <div className="flex items-center gap-4 p-4 bg-white/5 border border-white/10">
                            <div className="w-12 h-12 bg-primary/20 rounded-full flex items-center justify-center">
                                <Music className="w-6 h-6 text-primary" />
                            </div>
                            <div>
                                <h3 className="text-white font-bold text-sm">AUDIO TRANSCODING</h3>
                                <p className="text-[10px] text-white/40 font-mono">Configure generated quality variants.</p>
                            </div>
                        </div>

                        <form onSubmit={handleTranscodeSave} className="space-y-4">
                            <div className="p-4 border border-white/5 bg-black/40">
                                <div className="flex items-center justify-between">
                                    <label className="text-[10px] text-primary font-bold tracking-widest block">
                                        TRANSCODE PROFILES
                                    </label>
                                    <button
                                        type="button"
                                        onClick={addProfile}
                                        className="text-[10px] text-primary border border-primary/30 px-3 py-1 hover:bg-primary hover:text-black transition-colors"
                                    >
                                        + ADD PROFILE
                                    </button>
                                </div>

                                <div className="mt-3 border border-white/10 rounded-lg overflow-hidden bg-gradient-to-b from-white/5 to-black/30">
                                    <div className="grid grid-cols-12 gap-2 px-3 py-2 text-[9px] text-white/60 font-mono border-b border-white/10 bg-black/40">
                                        <div className="col-span-2">ID</div>
                                        <div className="col-span-2">LABEL</div>
                                        <div className="col-span-2">FORMAT</div>
                                        <div className="col-span-3">CODEC</div>
                                        <div className="col-span-2">QUALITY</div>
                                        <div className="col-span-1">ACTIONS</div>
                                    </div>
                                    {transcodeSettings.profiles.map((profile, index) => (
                                        <div key={index} className="grid grid-cols-12 gap-2 px-3 py-2 text-[10px] text-white/85 font-mono border-b border-white/5 hover:bg-white/5 transition-colors">
                                            <input
                                                className="col-span-2 bg-black/60 border border-white/10 px-2 py-2"
                                                value={profile.variant || ''}
                                                onChange={(e) => updateProfile(index, { variant: e.target.value })}
                                                placeholder="160k"
                                            />
                                            <input
                                                className="col-span-2 bg-black/60 border border-white/10 px-2 py-2"
                                                value={profile.label || ''}
                                                onChange={(e) => updateProfile(index, { label: e.target.value })}
                                                placeholder="160kbps"
                                            />
                                            <select
                                                className="col-span-2 bg-black/60 border border-white/10 px-2 py-2"
                                                value={profile.format || ''}
                                                onChange={(e) => updateProfile(index, { format: e.target.value })}
                                            >
                                                <option value="" disabled>format</option>
                                                <option value="m4a">m4a</option>
                                                <option value="ogg">ogg</option>
                                                <option value="flac">flac</option>
                                                <option value="wav">wav</option>
                                                <option value="mp3">mp3</option>
                                            </select>
                                            <select
                                                className="col-span-3 bg-black/60 border border-white/10 px-2 py-2"
                                                value={profile.codec || ''}
                                                onChange={(e) => updateProfile(index, { codec: e.target.value })}
                                            >
                                                <option value="" disabled>codec</option>
                                                <option value="alac">alac</option>
                                                <option value="flac">flac</option>
                                                <option value="libvorbis">libvorbis</option>
                                            </select>
                                            <select
                                                className="col-span-2 bg-black/60 border border-white/10 px-2 py-2"
                                                value={profile.lossless ? 'lossless' : String(profile.bitrate_kbps || 160)}
                                                onChange={(e) => {
                                                    const raw = e.target.value;
                                                    updateProfile(index, {
                                                        bitrate_kbps: raw === 'lossless' ? 0 : parseInt(raw, 10),
                                                        lossless: raw === 'lossless',
                                                    });
                                                }}
                                            >
                                                <option value="lossless">lossless</option>
                                                {profile.bitrate_kbps > 0 && ![64, 96, 128, 160, 192, 256, 320].includes(profile.bitrate_kbps) && (
                                                    <option value={String(profile.bitrate_kbps)}>
                                                        custom {profile.bitrate_kbps}
                                                    </option>
                                                )}
                                                <option value="64">64</option>
                                                <option value="96">96</option>
                                                <option value="128">128</option>
                                                <option value="160">160</option>
                                                <option value="192">192</option>
                                                <option value="256">256</option>
                                                <option value="320">320</option>
                                            </select>
                                            <div className="col-span-1 flex items-center justify-end">
                                                <Button
                                                    type="button"
                                                    variant="ghost"
                                                    size="icon-sm"
                                                    onClick={() => removeProfile(index)}
                                                    className="text-red-500 hover:text-red-400 hover:bg-red-500/10"
                                                    title="Remove profile"
                                                >
                                                    <span className="sr-only">Remove profile</span>
                                                    <Trash2 className="h-4 w-4" />
                                                </Button>
                                            </div>
                                        </div>
                                    ))}
                                    {transcodeSettings.profiles.length === 0 && (
                                        <div className="px-3 py-3 text-[10px] text-white/40 font-mono">
                                            No profiles configured.
                                        </div>
                                    )}
                                </div>
                                <p className="text-[10px] text-white/30 font-mono mt-2">
                                    Lossless profiles are skipped for lossy sources. Higher or equal bitrate targets are skipped for lossy sources.
                                </p>
                            </div>

                            <button disabled={transcodeLoading} className="bg-primary/10 border border-primary/30 text-primary px-6 py-3 font-bold text-xs hover:bg-primary hover:text-black transition-colors flex items-center gap-2 cursor-pointer">
                                <Save className="w-4 h-4" /> {transcodeLoading ? 'SAVING...' : 'SAVE TRANSCODE SETTINGS'}
                            </button>
                        </form>

                        <div className="p-4 border border-white/5 bg-black/40">
                            <h4 className="text-white text-xs font-bold mb-2">TRANSCODE BACKFILL</h4>
                            <p className="text-[10px] text-white/40 font-mono mb-4">
                                Generate missing variants for existing songs after upgrades.
                                Uses the best available source file.
                            </p>

                            <button
                                onClick={handleBackfill}
                                disabled={backfillLoading}
                                className="bg-white/5 border border-white/20 text-white/80 px-6 py-3 font-bold text-xs hover:bg-white hover:text-black transition-colors flex items-center gap-2 cursor-pointer"
                            >
                                <RefreshCw className={`w-4 h-4 ${backfillLoading ? 'animate-spin' : ''}`} /> {backfillLoading ? 'BACKFILLING...' : 'RUN BACKFILL'}
                            </button>
                        </div>
                    </div>
                )}

                {activeTab === 'maintenance' && (
                    <div className="space-y-8 animate-slide-in">
                        <div className="p-4 border border-white/5 bg-black/40">
                            <h4 className="text-white text-xs font-bold mb-2">SYSTEM MIGRATIONS</h4>
                            <p className="text-[10px] text-white/40 font-mono mb-4">
                                Background upgrade tasks run automatically. This view shows current progress.
                            </p>

                            {migrationLoading ? (
                                <p className="text-[10px] text-white/40 font-mono">Loading status...</p>
                            ) : migrationStatus ? (
                                <div className="space-y-3 text-[10px] text-white/70 font-mono">
                                    <div className="flex justify-between">
                                        <span>RUNNING</span>
                                        <span>{migrationStatus.running ? 'YES' : 'NO'}</span>
                                    </div>
                                    {migrationStatus.current_step && (
                                        <div className="flex justify-between">
                                            <span>ACTIVE STEP</span>
                                            <span>{migrationStatus.current_step}</span>
                                        </div>
                                    )}
                                    {migrationStatus.steps && Object.entries(migrationStatus.steps).map(([key, step]) => (
                                        <div key={key} className="flex justify-between">
                                            <span>{key}</span>
                                            <span>{step.state}{step.processed ? ` (${step.processed}/${step.total || '?'})` : ''}</span>
                                        </div>
                                    ))}
                                </div>
                            ) : (
                                <p className="text-[10px] text-white/40 font-mono">No migration data available.</p>
                            )}

                            <div className="flex gap-3 mt-4">
                                <button
                                    onClick={loadMigrationStatus}
                                    disabled={migrationLoading}
                                    className="bg-white/5 border border-white/20 text-white/80 px-4 py-2 font-bold text-[10px] hover:bg-white hover:text-black transition-colors flex items-center gap-2 cursor-pointer"
                                >
                                    <RefreshCw className={`w-3 h-3 ${migrationLoading ? 'animate-spin' : ''}`} /> REFRESH
                                </button>
                                <button
                                    onClick={handleRetryMigrations}
                                    disabled={migrationRetryLoading}
                                    className="bg-red-500/10 border border-red-500/30 text-red-400 px-4 py-2 font-bold text-[10px] hover:bg-red-500 hover:text-black transition-colors flex items-center gap-2 cursor-pointer"
                                >
                                    <Wrench className={`w-3 h-3 ${migrationRetryLoading ? 'animate-spin' : ''}`} /> RETRY
                                </button>
                            </div>
                        </div>
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

                        <div className="p-4 border border-white/5 bg-black/40">
                            <h4 className="text-white text-xs font-bold mb-2">FILE METADATA BACKFILL</h4>
                            <p className="text-[10px] text-white/40 font-mono mb-4">
                                Backfill missing song file duration and size metadata.
                                Safe to run after server upgrades.
                            </p>

                            <button
                                onClick={handleDoctor}
                                disabled={doctorLoading}
                                className="bg-white/5 border border-white/20 text-white/80 px-6 py-3 font-bold text-xs hover:bg-white hover:text-black transition-colors flex items-center gap-2 cursor-pointer"
                            >
                                <Wrench className={`w-4 h-4 ${doctorLoading ? 'animate-spin' : ''}`} /> {doctorLoading ? 'RUNNING...' : 'RUN BACKFILL'}
                            </button>
                        </div>
                    </div>
                )}
            </div>
        </main>
    );
}

export default SettingsView;
