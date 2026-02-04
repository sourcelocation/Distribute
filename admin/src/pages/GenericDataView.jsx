import React, { useEffect, useState } from 'react';
import DataTable from '../components/DataTable';
import { Database, Music, Mic, PlayCircle } from 'lucide-react';
import api from '../api';

const GenericDataView = ({ title, icon: Icon, endpoint, columns, addLabel, actions, createAction }) => {
    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(false);
    const [page, setPage] = useState(1);
    const [hasNext, setHasNext] = useState(false);
    const limit = 10;

    const fetchData = async () => {
        setLoading(true);
        try {
            const res = await api.get(`${endpoint}?page=${page}&limit=${limit}`);
            if (Array.isArray(res.data)) {
                // Legacy support just in case
                setData(res.data.slice((page - 1) * limit, page * limit));
                setHasNext(res.data.length > page * limit);
            } else if (res.data.data) {
                setData(res.data.data);
                // Support both legacy "total" and new "has_next" backend responses
                if (res.data.has_next !== undefined) {
                    setHasNext(res.data.has_next);
                } else if (res.data.total) {
                    setHasNext(page * limit < res.data.total);
                }
            }
        } catch (e) {
            console.error(`Failed to fetch ${title}`, e);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchData();
    }, [page, endpoint]);

    return (
        <main className="flex-1 overflow-hidden grid-bg p-6 flex flex-col gap-6 animate-slide-in">
            <div className="flex justify-between items-end">
                <div>
                    <h2 className="text-2xl font-bold text-white tracking-[0.1em] flex items-center gap-3">
                        <Icon className="w-6 h-6 text-primary" /> {title}
                    </h2>
                </div>

                {createAction && typeof createAction === 'function' ? (
                    <div className="flex gap-2">
                        {createAction(fetchData)}
                    </div>
                ) : (
                    addLabel && (
                        <button className="px-4 py-2 bg-primary text-black font-bold text-xs tracking-widest flex items-center gap-2 hover:opacity-90">
                            + {addLabel}
                        </button>
                    )
                )}
            </div>

            <DataTable
                columns={columns}
                data={data}
                hasNext={hasNext}
                page={page}
                limit={limit}
                loading={loading}
                onPageChange={setPage}
                actions={actions}
            />
        </main >
    );
};

export default GenericDataView;
