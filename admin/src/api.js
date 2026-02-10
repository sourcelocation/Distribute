import axios from 'axios';

const api = axios.create({
    baseURL: import.meta.env.VITE_API_URL || "/api",
    headers: {
        'Content-Type': 'application/json',
    },
});

api.interceptors.request.use(
    (config) => {
        const token = localStorage.getItem('token');
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
    },
    (error) => Promise.reject(error)
);

api.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response && error.response.status === 401) {
            if (!window.location.pathname.includes('/login')) {
                localStorage.removeItem('token');
                localStorage.removeItem('user');
                window.location.href = '/login';
            }
        }
        return Promise.reject(error);
    }
);

export default api;

export const buildApiUrl = (path) => {
    const base = api.defaults.baseURL || '';
    const cleanPath = path.startsWith('/') ? path : `/${path}`;
    if (!base) return cleanPath;
    if (/^https?:\/\//i.test(base)) {
        const baseUrl = base.endsWith('/') ? base : `${base}/`;
        return new URL(cleanPath.replace(/^\//, ''), baseUrl).toString();
    }
    const trimmedBase = base.endsWith('/') ? base.slice(0, -1) : base;
    return `${trimmedBase}${cleanPath}`;
};
