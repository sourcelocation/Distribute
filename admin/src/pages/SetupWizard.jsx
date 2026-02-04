import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { CornerBrackets, GlowBorders } from '../components/FUI';
import { Shield, Server, CheckCircle, ArrowRight, Music, Mail } from 'lucide-react';
import api from '../api';

const SetupWizard = () => {
    const navigate = useNavigate();
    const [step, setStep] = useState(1);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const [formData, setFormData] = useState({
        username: '',
        password: '',
        server_url: 'http://localhost:8585',
        mail_categories: 'song_only,album,playlist',
        request_mail_announcement: 'Feel free to request more music!'
    });

    useEffect(() => {
        // Check if already setup
        const checkStatus = async () => {
            try {
                const res = await api.get('/setup/status');
                if (res.data.setup_complete) {
                    navigate('/login');
                }
            } catch (e) {
                console.error(e);
            }
        };
        checkStatus();
    }, [navigate]);

    const handleNext = () => {
        if (validateStep()) {
            setStep(s => s + 1);
            setError('');
        }
    };

    const validateStep = () => {
        if (step === 2) {
            if (!formData.username || !formData.password) {
                setError('Username and password are required');
                return false;
            }
            if (formData.password.length < 8) {
                setError('Password must be at least 8 characters');
                return false;
            }
        }
        if (step === 3) {
            if (!formData.server_url) {
                setError('Server URL is required');
                return false;
            }
        }
        return true;
    };

    const handleSubmit = async () => {
        setLoading(true);
        setError('');
        try {
            await api.post('/setup/complete', formData);
            setStep(4);
            setTimeout(() => {
                navigate('/login');
            }, 3000);
        } catch (e) {
            setError(e.response?.data?.error || 'Setup failed');
        } finally {
            setLoading(false);
        }
    };

    const renderStep = () => {
        switch (step) {
            case 1:
                return (
                    <div className="text-center animate-slide-in">
                        <div className="w-20 h-20 bg-primary/20 rounded-full flex items-center justify-center mx-auto mb-6">
                            <Shield className="w-10 h-10 text-primary animate-pulse" />
                        </div>
                        <h1 className="text-3xl font-bold text-white tracking-[0.2em] mb-4">Distributor</h1>
                        <p className="text-white/40 font-mono mb-8 max-w-md mx-auto">
                            Before we can begin, we need to configure some basic settings.
                        </p>
                        <button onClick={() => setStep(2)} className="bg-primary hover:bg-white hover:text-black text-black px-8 py-3 font-bold tracking-widest transition-all">
                            Continue
                        </button>
                    </div>
                );
            case 2:
                return (
                    <div className="animate-slide-in space-y-6">
                        <div className="flex items-center gap-4 mb-8 border-b border-white/10 pb-4">
                            <div className="w-10 h-10 bg-primary/20 rounded-full flex items-center justify-center">
                                <Shield className="w-5 h-5 text-primary" />
                            </div>
                            <div>
                                <h2 className="text-xl font-bold text-white tracking-widest">ADMIN ACCESS</h2>
                                <p className="text-[10px] text-white/40 font-mono">Create the root administrator account.</p>
                            </div>
                        </div>

                        <div className="space-y-4">
                            <div className="space-y-1">
                                <label className="text-[10px] text-primary font-bold tracking-widest block">ADMIN USERNAME</label>
                                <input
                                    type="text"
                                    value={formData.username}
                                    onChange={(e) => setFormData({ ...formData, username: e.target.value })}
                                    className="w-full bg-black/40 border border-white/10 p-3 text-white font-mono text-sm focus:border-primary focus:outline-none"
                                    placeholder="root"
                                />
                            </div>
                            <div className="space-y-1">
                                <label className="text-[10px] text-primary font-bold tracking-widest block">PASSWORD</label>
                                <input
                                    type="password"
                                    value={formData.password}
                                    onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                                    className="w-full bg-black/40 border border-white/10 p-3 text-white font-mono text-sm focus:border-primary focus:outline-none"
                                    placeholder="••••••••"
                                />
                            </div>
                        </div>

                        <div className="flex justify-end pt-4">
                            <button onClick={handleNext} className="border border-primary/30 text-primary hover:bg-primary/10 px-6 py-2 font-bold tracking-widest transition-all flex items-center gap-2">
                                NEXT STEP <ArrowRight className="w-4 h-4" />
                            </button>
                        </div>
                    </div>
                );
            case 3:
                return (
                    <div className="animate-slide-in space-y-6">
                        <div className="flex items-center gap-4 mb-8 border-b border-white/10 pb-4">
                            <div className="w-10 h-10 bg-secondary/20 rounded-full flex items-center justify-center">
                                <Server className="w-5 h-5 text-secondary" />
                            </div>
                            <div>
                                <h2 className="text-xl font-bold text-white tracking-widest">SERVER CONFIG</h2>
                                <p className="text-[10px] text-white/40 font-mono">Configure instance parameters.</p>
                            </div>
                        </div>

                        <div className="space-y-4">
                            <div className="space-y-1">
                                <label className="text-[10px] text-primary font-bold tracking-widest block">PUBLIC SERVER URL</label>
                                <input
                                    type="text"
                                    value={formData.server_url}
                                    onChange={(e) => setFormData({ ...formData, server_url: e.target.value })}
                                    className="w-full bg-black/40 border border-white/10 p-3 text-white font-mono text-sm focus:border-primary focus:outline-none"
                                />
                            </div>
                            <div className="space-y-1">
                                <label className="text-[10px] text-primary font-bold tracking-widest block flex items-center gap-2">
                                    MAIL CATEGORIES <Mail className="w-3 h-3" />
                                </label>
                                <input
                                    type="text"
                                    value={formData.mail_categories}
                                    onChange={(e) => setFormData({ ...formData, mail_categories: e.target.value })}
                                    className="w-full bg-black/40 border border-white/10 p-3 text-white font-mono text-sm focus:border-primary focus:outline-none"
                                    placeholder="song_only,album,playlist"
                                />
                                <p className="text-[10px] text-white/30 font-mono">Comma separated list of allowed request types.</p>
                            </div>
                            <div className="space-y-1">
                                <label className="text-[10px] text-primary font-bold tracking-widest block">ANNOUNCEMENT MESSAGE</label>
                                <textarea
                                    value={formData.request_mail_announcement}
                                    onChange={(e) => setFormData({ ...formData, request_mail_announcement: e.target.value })}
                                    className="w-full bg-black/40 border border-white/10 p-3 text-white font-mono text-sm focus:border-primary focus:outline-none h-20 resize-none"
                                />
                            </div>
                        </div>

                        <div className="flex justify-between pt-4">
                            <button onClick={() => setStep(2)} className="text-white/40 hover:text-white px-4 py-2 font-mono text-xs transition-all">
                                BACK
                            </button>
                            <button onClick={handleSubmit} disabled={loading} className="bg-primary text-black hover:bg-white px-6 py-2 font-bold tracking-widest transition-all flex items-center gap-2">
                                {loading ? 'INSTALLING...' : 'COMPLETE SETUP'} <CheckCircle className="w-4 h-4" />
                            </button>
                        </div>
                    </div>
                );
            case 4:
                return (
                    <div className="text-center animate-slide-in py-10">
                        <CheckCircle className="w-20 h-20 text-primary mx-auto mb-6 animate-bounce" />
                        <h1 className="text-2xl font-bold text-white tracking-widest mb-4">SETUP COMPLETE</h1>
                        <p className="text-white/40 font-mono">Redirecting to login...</p>
                    </div>
                );
            default:
                return null;
        }
    };

    return (
        <div className="h-screen bg-bg-dark flex items-center justify-center relative overflow-hidden ">
            <div className="absolute inset-0 bg-gradient-to-t from-bg-dark via-transparent to-transparent opacity-80 pointer-events-none"></div>

            <div className="max-w-xl w-full p-1 bg-gradient-to-br from-white/10 to-transparent relative">
                <div className="bg-bg-dark/90 backdrop-blur-xl p-8 relative overflow-hidden min-h-[500px] flex flex-col justify-center">

                    <div className="corner-bracket corner-bl"></div>
                    <div className="corner-bracket corner-br"></div>
                    <GlowBorders />

                    {/* Progress Bar */}
                    {step < 4 && (
                        <div className="absolute top-0 left-0 w-full h-1 bg-white/5">
                            <div
                                className="h-full bg-primary transition-all duration-500 ease-out"
                                style={{ width: `${((step - 1) / 2) * 100}%` }}
                            ></div>
                        </div>
                    )}

                    {error && (
                        <div className="bg-red-500/10 border border-red-500/30 text-red-500 p-3 mb-6 font-mono text-xs text-center animate-slide-in">
                            {error}
                        </div>
                    )}

                    {renderStep()}
                </div>
            </div>
        </div>
    );
};

export default SetupWizard;
