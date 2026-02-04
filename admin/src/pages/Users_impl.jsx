import React, { useEffect, useState } from 'react';
import DataTable from '../components/DataTable';
import { CornerBrackets } from '../components/FUI';
import { Trash2, UserPlus, Shield, Users } from 'lucide-react';
import api from '../api';

const UsersView = () => {
    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(false);
    const [page, setPage] = useState(1);
    const [total, setTotal] = useState(0);
    const limit = 10;

    const fetchUsers = async () => {
        setLoading(true);
        try {
            const res = await api.get(`/admin/users?page=${page}&limit=${limit}`);
            setData(res.data.data);
            setTotal(res.data.total);
        } catch (e) {
            console.error("Failed to fetch users", e);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchUsers();
    }, [page]);

    const handleDelete = async (id) => {
        if (!confirm("Are you sure you want to delete this user?")) return;
        try {
            await api.delete(`/users/${id}`); // Generic user delete endpoint
            fetchUsers();
        } catch (e) {
            alert("Failed to delete user");
        }
    }

    const columns = [
        { header: 'ID', accessor: 'ID', render: (u) => <span className="font-mono text-[9px] text-white/30">{u.ID}</span> },
        { header: 'USERNAME', accessor: 'Username', render: (u) => <span className="text-white font-bold">{u.Username}</span> },
        { header: 'ROLE', accessor: 'IsAdmin', render: (u) => u.IsAdmin ? <span className="text-primary font-bold flex items-center gap-1"><Shield className="w-3 h-3" /> ADMIN</span> : <span className="text-white/50">USER</span> },
        { header: 'CREATED', accessor: 'CreatedAt', render: (u) => new Date(u.CreatedAt).toLocaleDateString() },
    ];

    return (
        <main className="flex-1 overflow-hidden grid-bg p-6 flex flex-col gap-6 animate-slide-in">
            <div className="flex justify-between items-end">
                <div>
                    <h2 className="text-2xl font-bold text-white tracking-[0.1em] flex items-center gap-3">
                        <Users className="w-6 h-6 text-primary" /> USER MANAGEMENT
                    </h2>
                    <p className="text-[10px] text-white/40 font-mono mt-1">Manage robust access control.</p>
                </div>
                <button className="px-4 py-2 bg-primary text-black font-bold text-xs tracking-widest flex items-center gap-2 hover:opacity-90 cursor-pointer">
                    <UserPlus className="w-4 h-4" /> ADD USER
                </button>
            </div>

            <DataTable
                columns={columns}
                data={data}
                total={total}
                page={page}
                limit={limit}
                loading={loading}
                onPageChange={setPage}
                actions={(row) => (
                    <button
                        onClick={() => handleDelete(row.ID)}
                        className="p-2 hover:bg-red-500/20 hover:text-red-500 rounded transition-colors cursor-pointer"
                        title="Delete User"
                    >
                        <Trash2 className="w-4 h-4" />
                    </button>
                )}
            />
        </main>
    );
};

export default UsersView;
