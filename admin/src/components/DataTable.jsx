import React from 'react';
import { ChevronLeft, ChevronRight, Loader } from 'lucide-react';

const DataTable = ({ columns, data, hasNext, page, limit, onPageChange, loading, actions }) => {

    return (
        <div className="flex flex-col h-full overflow-hidden panel relative">
            <div className="overflow-auto flex-1 custom-scrollbar">
                <table className="w-full text-left border-collapse">
                    <thead className="sticky top-0 bg-black/80 backdrop-blur-md z-10 border-b border-primary/20 text-[10px] text-primary font-bold tracking-widest uppercase shadow-lg">
                        <tr>
                            {columns.map((col, i) => (
                                <th key={i} className="pl-8 p-4 whitespace-nowrap">{col.header || col.label}</th>
                            ))}
                            {actions && <th className="p-4 text-right">ACTIONS</th>}
                        </tr>
                    </thead>
                    <tbody className="text-xs font-mono text-slate-400 divide-y divide-white/5">
                        {loading ? (
                            <tr>
                                <td colSpan={columns.length + (actions ? 1 : 0)} className="p-12 text-center text-white/20">
                                    <Loader className="w-8 h-8 animate-spin mx-auto mb-2 opacity-50" />
                                    LOADING DATA...
                                </td>
                            </tr>
                        ) : data.length === 0 ? (
                            <tr>
                                <td colSpan={columns.length + (actions ? 1 : 0)} className="p-12 text-center text-white/20">
                                    NO RECORDS FOUND
                                </td>
                            </tr>
                        ) : (
                            data.map((row, i) => (
                                <tr key={i} className="hover:bg-white/5 transition-colors group">
                                    {columns.map((col, j) => {
                                        const accessor = col.accessor || col.key;
                                        // Handle nested keys like "album.title"
                                        const value = accessor.split('.').reduce((obj, key) => obj?.[key], row);

                                        return (
                                            <td key={j} className="pl-8 pt-2 pb-2 whitespace-nowrap overflow-hidden text-ellipsis max-w-[200px]">
                                                {col.render ? col.render(row) : value}
                                            </td>
                                        );
                                    })}
                                    {actions && (
                                        <td className="p-4 text-right">
                                            {actions(row)}
                                        </td>
                                    )}
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {/* Pagination Footer */}
            <div className="border-t border-white/10 bg-white/5 p-3 flex justify-between items-center text-[10px] font-mono">
                <div className="text-white/40">
                    SHOWING {data.length} RECORDS
                </div>
                <div className="flex items-center gap-2">
                    <button
                        disabled={page <= 1}
                        onClick={() => onPageChange(page - 1)}
                        className="p-1 hover:bg-white/10 disabled:opacity-30 disabled:hover:bg-transparent transition-colors"
                    >
                        <ChevronLeft className="w-4 h-4" />
                    </button>
                    <span className="text-primary font-bold">PAGE {page}</span>
                    <button
                        disabled={!hasNext}
                        onClick={() => onPageChange(page + 1)}
                        className="p-1 hover:bg-white/10 disabled:opacity-30 disabled:hover:bg-transparent transition-colors"
                    >
                        <ChevronRight className="w-4 h-4" />
                    </button>
                </div>
            </div>
        </div>
    );
};

export default DataTable;
