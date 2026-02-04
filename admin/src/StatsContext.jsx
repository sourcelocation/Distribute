import React, { createContext, useContext, useState, useEffect } from 'react';
import api from './api';
import { useAuth } from './AuthContext';

const StatsContext = createContext(null);

export const StatsProvider = ({ children }) => {
    const [stats, setStats] = useState(null);
    const { user } = useAuth(); // Only fetch if authenticated

    const fetchStats = async () => {
        if (!user) return;
        try {
            const res = await api.get('/admin/stats');
            setStats(res.data);
        } catch (e) {
            console.error("Failed to fetch global stats", e);
        }
    };

    useEffect(() => {
        if (!user) return;

        fetchStats();
        // Poll every 5 seconds
        const interval = setInterval(fetchStats, 5000);
        return () => clearInterval(interval);
    }, [user]);

    return (
        <StatsContext.Provider value={{ stats, refreshStats: fetchStats }}>
            {children}
        </StatsContext.Provider>
    );
};

export const useStats = () => useContext(StatsContext);
