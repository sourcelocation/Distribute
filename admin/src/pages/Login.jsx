import React, { useState } from 'react';
import { useAuth } from '../AuthContext';
import { CornerBrackets, GlowBorders } from '../components/FUI';
import { ShieldAlert } from 'lucide-react';

const Login = () => {
    const { login } = useAuth();
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        try {
            await login(username, password);
            window.location.href = '/';
        } catch (err) {
            setError('AUTHENTICATION FAILED: ' + (err.response?.data?.error || err.message));
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="h-screen bg-bg-dark flex items-center justify-center relative overflow-hidden">
            <div className="scanline"></div>
            <div className="max-w-md w-full p-8 panel relative bg-black/40 backdrop-blur-sm border border-primary/20">
                <CornerBrackets />
                <GlowBorders h={true} v={true} />

                <div className="text-center mb-8">
                    <ShieldAlert className="w-12 h-12 text-primary mx-auto mb-4 animate-pulse" />
                    <h1 className="text-2xl font-bold text-white tracking-[0.2em]">LOGIN</h1>
                    <p className="text-[10px] text-white/40 font-mono mt-2">ENTER YOUR CREDENTIALS TO ACCESS DISTRIBUTOR</p>
                </div>

                <form onSubmit={handleSubmit} className="space-y-6">
                    <div className="space-y-1">
                        <label className="text-[10px] text-primary font-bold tracking-widest block">USERNAME</label>
                        <input
                            type="text"
                            value={username}
                            onChange={(e) => setUsername(e.target.value)}
                            className="w-full bg-white/5 border border-white/10 p-3 text-white font-mono text-sm focus:border-primary focus:outline-none transition-colors"
                            placeholder="ENTER USERNAME..."
                        />
                    </div>
                    <div className="space-y-1">
                        <label className="text-[10px] text-primary font-bold tracking-widest block">PASSWORD</label>
                        <input
                            type="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            className="w-full bg-white/5 border border-white/10 p-3 text-white font-mono text-sm focus:border-primary focus:outline-none transition-colors"
                            placeholder="••••••••"
                        />
                    </div>

                    {error && (
                        <div className="p-3 bg-red-400/10 border border-red-400/30 text-red-400 text-xs font-mono">
                            {error}
                        </div>
                    )}

                    <button
                        type="submit"
                        disabled={loading}
                        className="w-full bg-primary/10 border border-primary/30 text-primary py-3 hover:bg-primary hover:text-black transition-all font-bold tracking-widest text-xs relative group"
                    >
                        {loading ? 'AUTHENTICATING...' : 'LOG IN'}
                        <div className="absolute inset-0 border border-primary/20 scale-105 opacity-0 group-hover:opacity-100 group-hover:scale-110 transition-all duration-500"></div>
                    </button>
                </form>

                <div className="mt-8 pt-4 border-t border-white/5 flex justify-between text-[10px] font-mono text-white/30">
                    <span>If you have forgotten your password, please reset it using CLI.</span>
                </div>
            </div>
        </div>
    );
};

export default Login;
