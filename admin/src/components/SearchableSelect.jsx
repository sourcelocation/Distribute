import React, { useState, useEffect, useRef } from 'react';
import { X, Search, Check, Loader } from 'lucide-react';
import api from '../api';

const SearchableSelect = ({
    value,
    onChange,
    multiple = false,
    type,
    placeholder = "Search...",
    label
}) => {
    const [query, setQuery] = useState('');
    const [results, setResults] = useState([]);
    const [loading, setLoading] = useState(false);
    const [isOpen, setIsOpen] = useState(false);
    const wrapperRef = useRef(null);

    // Handle clicks outside to close dropdown
    useEffect(() => {
        const handleClickOutside = (event) => {
            if (wrapperRef.current && !wrapperRef.current.contains(event.target)) {
                setIsOpen(false);
            }
        };
        document.addEventListener("mousedown", handleClickOutside);
        return () => document.removeEventListener("mousedown", handleClickOutside);
    }, [wrapperRef]);

    useEffect(() => {
        const delayDebounceFn = setTimeout(() => {
            if (query && isOpen) {
                search();
            }
        }, 300);

        return () => clearTimeout(delayDebounceFn);
    }, [query]);

    const search = async () => {
        setLoading(true);
        try {
            const res = await api.get(`/search?q=${encodeURIComponent(query)}&type=${type}&limit=10`);
            setResults(res.data || []);
        } catch (error) {
            console.error("Search failed", error);
        } finally {
            setLoading(false);
        }
    };

    const handleSelect = (item) => {
        if (multiple) {
            const current = Array.isArray(value) ? value : [];
            // Check duplicates
            if (!current.some(i => i.id === item.id)) {
                // Determine label based on item type or properties
                // Search result has title, sub.
                // We want to store { id, name: title } usually
                const newItem = { id: item.id, name: item.title, identifier: item.sub };
                onChange([...current, newItem]);
            }
            setQuery(''); // Clear query after selection?
        } else {
            const newItem = { id: item.id, name: item.title, identifier: item.sub };
            onChange(newItem);
            setIsOpen(false);
            setQuery(''); // Clear query
        }
    };

    const handleRemove = (itemToRemove) => {
        if (multiple) {
            const current = Array.isArray(value) ? value : [];
            onChange(current.filter(i => i.id !== itemToRemove.id));
        } else {
            onChange(null);
        }
    };

    const renderSelected = () => {
        if (multiple) {
            return (
                <div className="flex flex-wrap gap-2 mb-2">
                    {(Array.isArray(value) ? value : []).map((item, idx) => (
                        <span key={item.id || idx} className="bg-primary/20 text-primary px-2 py-1 text-xs font-mono flex items-center gap-1 rounded">
                            {item.name}
                            <button onClick={(e) => { e.stopPropagation(); handleRemove(item); }} className="hover:text-white">
                                <X className="w-3 h-3" />
                            </button>
                        </span>
                    ))}
                </div>
            );
        } else {
            // For single selection, we might display it in the input or as a block
            if (value && value.name) {
                return (
                    <div className="flex items-center justify-between bg-white/5 p-2 mb-2 rounded border border-white/10">
                        <span className="text-primary text-sm font-bold">{value.name}</span>
                        <button onClick={() => handleRemove(value)} className="hover:text-red-500 text-white/40">
                            <X className="w-4 h-4" />
                        </button>
                    </div>
                );
            }
        }
        return null;
    };

    return (
        <div className="flex flex-col gap-2 relative" ref={wrapperRef}>
            {label && <label className="text-xs font-bold text-white/60 uppercase tracking-widest">{label}</label>}

            {renderSelected()}

            <div className="relative">
                <input
                    className="w-full bg-black/40 border border-white/10 p-3 text-white focus:border-primary outline-none transition-colors pl-10"
                    value={query}
                    onChange={(e) => {
                        setQuery(e.target.value);
                        setIsOpen(true);
                    }}
                    onFocus={() => setIsOpen(true)}
                    placeholder={placeholder}
                />
                <Search className="w-4 h-4 text-white/40 absolute left-3 top-3.5" />
                {loading && <Loader className="w-4 h-4 text-primary absolute right-3 top-3.5 animate-spin" />}
            </div>

            {isOpen && query && (
                <div className="absolute top-full left-0 right-0 mt-1 bg-zinc-900 border border-white/10 shadow-xl max-h-60 overflow-y-auto z-50">
                    {results.length === 0 && !loading ? (
                        <div className="p-3 text-white/20 text-sm italic">No results found</div>
                    ) : (
                        results.map((item) => (
                            <button
                                key={item.id}
                                onClick={() => handleSelect(item)}
                                className="w-full text-left p-3 hover:bg-white/5 flex items-center justify-between group transition-colors border-b border-white/5 last:border-0"
                            >
                                <div>
                                    <div className="text-white font-bold text-sm group-hover:text-primary transition-colors">{item.title}</div>
                                    {item.sub && <div className="text-white/40 text-xs font-mono">{item.sub}</div>}
                                </div>
                                {type === 'artist' && item.sub && (
                                    <div className="text-[10px] bg-white/10 px-1 py-0.5 rounded text-white/60">{item.sub}</div>
                                )}
                            </button>
                        ))
                    )}
                </div>
            )}
        </div>
    );
};

export default SearchableSelect;
