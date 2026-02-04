import React, { createContext, useContext, useState, useEffect } from 'react';
import api from './api';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [token, setToken] = useState(localStorage.getItem('token'));
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const initAuth = async () => {
            if (token) {
                try {
                    // Verify token if needed, or just load user from storage/api
                    const storedUser = localStorage.getItem('user');
                    if (storedUser) {
                        setUser(JSON.parse(storedUser));
                    } else {
                        const res = await api.get('/users/me');
                        setUser(res.data);
                    }
                } catch (e) {
                    console.error("Auth check failed", e);
                    logout();
                }
            }
            setLoading(false);
        };
        initAuth();
    }, [token]);

    const login = async (username, password) => {
        const res = await api.post('/users/login', { username, password });
        const { token, user } = res.data;
        localStorage.setItem('token', token);
        localStorage.setItem('user', JSON.stringify(user));
        setToken(token);
        setUser(user);
        return user;
    };

    const logout = () => {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        setToken(null);
        setUser(null);
    };

    const value = {
        user,
        token,
        login,
        logout,
        loading
    };

    return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => useContext(AuthContext);
