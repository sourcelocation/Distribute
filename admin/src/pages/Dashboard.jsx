import React, { useEffect, useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import StatCard from '../components/StatCard';
import { CornerBrackets } from '../components/FUI';
import { Activity, Power, RotateCcw, Trash2, Zap } from 'lucide-react';
import api from '../api';
import { useStats } from '../StatsContext';

const formatBytes = (bytes) => {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
};

const formatUptime = (seconds) => {
    if (!seconds) return "0:00";
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    if (h > 0) {
        return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    }
    return `${m}:${s.toString().padStart(2, '0')}`;
};

const BandwidthChart = ({ data }) => {
    const [hover, setHover] = useState(null);
    const containerRef = useRef(null);

    // Filter out bad data if any
    if (!data) return <div className="h-full flex items-center justify-center text-white/20 text-xs">NO DATA</div>;

    // Visual fix: If only 1 data point, prepend a 0 point to show growth
    let chartData = [...data];
    if (data.length === 1) {
        const first = data[0];
        // Create a fake previous point 15 mins ago
        const prevTime = new Date(new Date(first.timestamp).getTime() - 15 * 60 * 1000).toISOString();
        chartData = [{ timestamp: prevTime, bytes_in: 0, bytes_out: 0 }, ...data];
    }
    if (chartData.length === 0) return <div className="h-full flex items-center justify-center text-white/20 text-xs">NO DATA</div>;


    const maxVal = Math.max(...chartData.map(d => d.bytes_out + d.bytes_in), 1);

    // Generate Polygon Points
    const points = chartData.map((d, i) => {
        const x = (i / (chartData.length - 1)) * 100;
        const total = d.bytes_out + d.bytes_in;
        const y = 100 - (total / maxVal) * 100;
        return `${x},${y}`;
    }).join(' ');

    const handleMouseMove = (e) => {
        if (!containerRef.current) return;
        const rect = containerRef.current.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const width = rect.width;
        let index = Math.round((x / width) * (chartData.length - 1));
        index = Math.max(0, Math.min(index, chartData.length - 1));

        setHover({
            index,
            data: chartData[index],
            x: (index / (chartData.length - 1)) * 100
        });
    };

    return (
        <div
            className="w-full h-full relative group cursor-crosshair"
            ref={containerRef}
            onMouseMove={handleMouseMove}
            onMouseLeave={() => setHover(null)}
        >
            {/* Y Axis Labels */}
            <div className="absolute left-0 top-0 h-full w-full pointer-events-none z-0 flex flex-col justify-between text-[9px] text-white/20 font-mono py-1">
                <div className="border-t border-white/5 w-full flex items-center relative"><span className="absolute right-full pr-4 top-0 -translate-y-1/2">{formatBytes(maxVal)}/S</span></div>
                <div className="border-t border-dashed border-white/5 w-full flex items-center relative"><span className="absolute right-full pr-4 top-0 -translate-y-1/2">{formatBytes(maxVal / 2)}/S</span></div>
                <div className="border-t border-white/5 w-full flex items-center relative"><span className="absolute right-full pr-4 top-0 -translate-y-1/2">0 B/S</span></div>
            </div>

            <svg className="w-full h-full relative z-10" viewBox="0 0 100 100" preserveAspectRatio="none">
                <defs>
                    <linearGradient id="chartGradient" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="#00FFC2" stopOpacity="0.3" />
                        <stop offset="100%" stopColor="#00FFC2" stopOpacity="0" />
                    </linearGradient>
                </defs>
                <polygon points={`0,100 ${points} 100,100`} fill="url(#chartGradient)" />
                <polyline points={points} fill="none" stroke="#00FFC2" strokeWidth="0.5" vectorEffect="non-scaling-stroke" />
            </svg>

            {/* Hover Tooltip & Line */}
            {hover && (
                <>
                    {/* Vertical Line */}
                    <div
                        className="absolute top-0 bottom-0 w-px bg-white/40 z-20 pointer-events-none"
                        style={{ left: `${hover.x}%` }}
                    />

                    {/* Data Point Dot */}
                    <div
                        className="absolute w-2 h-2 bg-primary rounded-full z-30 pointer-events-none transform -translate-x-1/2 -translate-y-1/2 shadow-[0_0_10px_rgba(0,255,194,0.8)]"
                        style={{
                            left: `${hover.x}%`,
                            top: `${100 - ((hover.data.bytes_in + hover.data.bytes_out) / maxVal) * 100}%`
                        }}
                    />

                    {/* Tooltip Box */}
                    <div
                        className="absolute z-40 bg-black/90 border border-white/10 p-2 rounded text-[10px] whitespace-nowrap pointer-events-none backdrop-blur shadow-xl"
                        style={{
                            left: hover.x > 50 ? 'auto' : `${hover.x + 2}%`,
                            right: hover.x > 50 ? `${100 - hover.x + 2}%` : 'auto',
                            top: '10%'
                        }}
                    >
                        <div className="font-bold text-white mb-1">
                            {new Date(hover.data.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                        </div>
                        <div className="grid grid-cols-2 gap-x-3 gap-y-0.5 font-mono text-white/70">
                            <span>TOTAL:</span>
                            <span className="text-right text-primary">{formatBytes(hover.data.bytes_in + hover.data.bytes_out)}</span>
                            <span>IN:</span>
                            <span className="text-right">{formatBytes(hover.data.bytes_in)}</span>
                            <span>OUT:</span>
                            <span className="text-right">{formatBytes(hover.data.bytes_out)}</span>
                        </div>
                    </div>
                </>
            )}
        </div>
    );
};

const Dashboard = () => {
    const navigate = useNavigate();
    const { stats } = useStats();
    const [bandwidth, setBandwidth] = useState([]);
    const [logs, setLogs] = useState([]);
    const [liveUptime, setLiveUptime] = useState(0);

    const logsContainerRef = useRef(null);
    const [snapToBottom, setSnapToBottom] = useState(true);

    const handleLogsScroll = (e) => {
        const { scrollTop, scrollHeight, clientHeight } = e.target;
        // If within 50px of bottom, snap to bottom
        const isAtBottom = scrollHeight - scrollTop - clientHeight < 50;
        setSnapToBottom(isAtBottom);
    };

    useEffect(() => {
        if (snapToBottom && logsContainerRef.current) {
            logsContainerRef.current.scrollTop = logsContainerRef.current.scrollHeight;
        }
    }, [logs, snapToBottom]);

    const fetchData = async () => {
        try {
            const [bwRes, logsRes] = await Promise.all([
                api.get('/admin/bandwidth'),
                api.get('/admin/logs')
            ]);
            setBandwidth(bwRes.data);
            setLogs(logsRes.data || []);
        } catch (e) {
            console.error("Dashboard fetch error", e);
        }
    };

    useEffect(() => {
        fetchData();
        const interval = setInterval(fetchData, 5000); // Poll every 5s
        return () => clearInterval(interval);
    }, []);

    useEffect(() => {
        if (stats?.uptime) {
            if (Math.abs(stats.uptime - liveUptime) > 5) {
                setLiveUptime(stats.uptime);
            }
        }
    }, [stats]);

    useEffect(() => {
        const timer = setInterval(() => setLiveUptime(t => t + 1), 1000);
        return () => clearInterval(timer);
    }, []);

    return (
        <main className="flex-1 overflow-y-auto grid-bg p-6 flex flex-col gap-6 animate-slide-in">
            {/* Top Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                <StatCard title="TOTAL SONGS" value={stats?.total_songs || 0} sub="TRACKS" to="/songs" />
                <StatCard title="TOTAL ALBUMS" value={stats?.total_albums || 0} sub="ALBUMS" to="/albums" />
                <StatCard title="TOTAL USERS" value={stats?.total_users || 0} sub="ACTIVE ACCOUNTS" to="/users" />
                <StatCard title="UPTIME" value={formatUptime(liveUptime)} sub="SINCE RESTART" live={true} />
            </div>

            {/* Live Telemetry Chart */}
            <section className="panel p-6 relative">
                <CornerBrackets />
                <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-8">
                    <div className="flex items-center gap-3">
                        <div className="w-2 h-2 bg-primary"></div>
                        <span className="text-[11px] text-primary font-bold tracking-[0.2em]">BANDWIDTH</span>
                        <span className="text-white/20">/</span>
                        <span className="text-[11px] text-white/40 font-mono">OUTBOUND + INBOUND</span>
                    </div>
                    <div className="text-[10px] font-mono text-white/50">
                        MEM: {stats?.memory} | GOROUTINES: {stats?.goroutines}
                    </div>
                </div>

                <div className="relative h-64 w-full bg-white/[0.02] border border-white/5 pr-6 pl-16 pt-6 pb-6">
                    <BandwidthChart data={bandwidth} />
                    {/* X Axis Time Labels */}
                    <div className="absolute bottom-1 left-16 right-6 flex justify-between text-[9px] text-white/20 font-mono pointer-events-none">
                        <span>{(() => {
                            if (!bandwidth || bandwidth.length === 0) return '-24h';
                            let t = bandwidth[0].timestamp;
                            if (bandwidth.length === 1) {
                                t = new Date(new Date(t).getTime() - 15 * 60 * 1000).toISOString();
                            }
                            return new Date(t).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
                        })()}</span>
                        <span>{(() => {
                            if (!bandwidth || bandwidth.length === 0) return '-12h';
                            let start = bandwidth[0].timestamp;
                            if (bandwidth.length === 1) {
                                start = new Date(new Date(start).getTime() - 15 * 60 * 1000).toISOString();
                            }
                            const end = bandwidth[bandwidth.length - 1].timestamp;
                            const mid = new Date(start).getTime() + (new Date(end).getTime() - new Date(start).getTime()) / 2;
                            return new Date(mid).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
                        })()}</span>
                        <span>{(() => {
                            if (!bandwidth || bandwidth.length === 0) return 'NOW';
                            return new Date(bandwidth[bandwidth.length - 1].timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
                        })()}</span>
                    </div>
                </div>
            </section>

            {/* System Core Log */}
            <div className="panel p-5 min-h-[230px] flex flex-col relative">
                <CornerBrackets />
                {/* <GlowBorders v={true} /> */}
                <div className="flex justify-between items-center mb-4">
                    <div className="flex items-center gap-2">
                        <Activity className="w-3 h-3 text-primary" />
                        <span className="text-[11px] text-primary font-bold tracking-widest">SERVER_EVENTS.LOG</span>
                    </div>
                    <span className="text-[10px] font-mono text-white/30">TAIL -N 100</span>
                </div>
                <div
                    ref={logsContainerRef}
                    onScroll={handleLogsScroll}
                    className="flex-1 space-y-1 text-[10px] font-mono leading-relaxed bg-black/40 p-4 border border-white/5 overflow-y-auto max-h-[300px] custom-scrollbar"
                >
                    {(logs || []).map((line, i) => (
                        <div key={i} className="text-white/60 border-b border-white/5 pb-0.5 mb-0.5 hover:text-white transition-colors break-all">
                            <span className="text-primary mr-2">&gt;</span>{line}
                        </div>
                    ))}
                    {logs.length === 0 && <div className="text-white/30 italic">No logs available...</div>}
                </div>
            </div>

            {/* Action Buttons */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 pb-12">
                <button className="panel group p-4 flex flex-col items-center justify-center gap-2 hover:bg-white/5 transition-all text-slate-400 hover:text-white cursor-pointer">
                    <Power className="w-5 h-5 text-secondary" />
                    <span className="text-[10px] font-bold">SHUTDOWN</span>
                </button>
                <button className="panel group p-4 flex flex-col items-center justify-center gap-2 hover:bg-white/5 transition-all text-slate-400 hover:text-white cursor-pointer">
                    <RotateCcw className="w-5 h-5 text-primary" />
                    <span className="text-[10px] font-bold">REBOOT</span>
                </button>
                <button
                    onClick={() => navigate('/settings', { state: { activeTab: 'maintenance' } })}
                    className="panel group p-4 flex flex-col items-center justify-center gap-2 hover:bg-white/5 transition-all text-slate-400 hover:text-white cursor-pointer"
                >
                    <Trash2 className="w-5 h-5 text-white/40" />
                    <span className="text-[10px] font-bold">MAINTENANCE</span>
                </button>
                <button className="bg-primary text-black flex flex-col items-center justify-center gap-2 p-4 hover:opacity-90 transition-all cursor-pointer border-none font-bold">
                    <Zap className="w-5 h-5 fill-current" />
                    <span className="text-[10px] tracking-[0.2em]">USELESS BUTTON</span>
                </button>
            </div>

        </main>
    );
};

export default Dashboard;
