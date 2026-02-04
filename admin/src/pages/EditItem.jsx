import React, { useEffect, useState, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useDropzone } from 'react-dropzone';
import { Save, Trash2, ArrowLeft, Loader, Database, Mic, Music, PlayCircle, Upload, X, Check, Loader2 } from 'lucide-react';
import api from '../api';
import SearchableSelect from '../components/SearchableSelect';
import { ArtistPicker } from '../components/Pickers';
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Label } from "@/components/ui/label"

const EditItem = () => {
    const { type, id } = useParams();
    const navigate = useNavigate();
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [error, setError] = useState(null);

    // Form fields
    const [formData, setFormData] = useState({});
    const [coverFile, setCoverFile] = useState(null);

    // Album Song Management
    const [existingSongs, setExistingSongs] = useState([]);
    const [stagedSongs, setStagedSongs] = useState([]); // { file, title, artists, status, error }
    const [globalArtists, setGlobalArtists] = useState([]);
    const [uploading, setUploading] = useState(false);
    const [uploadProgress, setUploadProgress] = useState({ current: 0, total: 0 });

    // Song Files Management (Single Song)
    const [songFiles, setSongFiles] = useState([]);
    const [uploadingFile, setUploadingFile] = useState(false);

    const onDrop = useCallback(acceptedFiles => {
        if (acceptedFiles.length > 0) {
            const file = acceptedFiles[0];
            const objectUrl = URL.createObjectURL(file);
            const img = new Image();
            img.src = objectUrl;

            img.onload = () => {
                if (img.width !== img.height) {
                    alert(`Image must be 1x1 (square). Current dimensions: ${img.width}x${img.height}`);
                    URL.revokeObjectURL(objectUrl);
                    return;
                }
                setCoverFile(file);
                URL.revokeObjectURL(objectUrl);
            };

            img.onerror = () => {
                alert("Failed to confirm image dimensions.");
                URL.revokeObjectURL(objectUrl);
            };
        }
    }, []);

    const { getRootProps: getCoverRoot, getInputProps: getCoverInput, isDragActive: isCoverDrag } = useDropzone({
        onDrop,
        maxFiles: 1,
        accept: { 'image/jpeg': ['.jpg', '.jpeg'] },
        disabled: type !== 'albums'
    });

    const onSongsDrop = useCallback(acceptedFiles => {
        const newSongs = acceptedFiles.map(file => ({
            file,
            title: file.name.replace(/\.[^/.]+$/, ""), // Remove extension
            artists: [...globalArtists], // Apply global artists by default
            status: 'pending' // pending, success, error
        }));
        setStagedSongs(prev => [...prev, ...newSongs]);
    }, [globalArtists]);

    const { getRootProps: getSongsRoot, getInputProps: getSongsInput, isDragActive: isSongsDrag } = useDropzone({
        onDrop: onSongsDrop,
        accept: { 'audio/*': ['.mp3', '.flac', '.wav', '.ogg', '.m4a'] }
    });

    // Song Files Dropzone (for type === 'songs')
    const onSongFileDrop = useCallback(async (acceptedFiles) => {
        if (acceptedFiles.length === 0) return;
        setUploadingFile(true);
        try {
            for (const file of acceptedFiles) {
                const formData = new FormData();
                formData.append('song_id', id);
                formData.append('file', file);
                await api.post('/songs/assign-file', formData, {
                    headers: { 'Content-Type': 'multipart/form-data' }
                });
            }
            fetchSongFiles();
        } catch (e) {
            alert("Failed to upload file: " + (e.response?.data?.error || e.message));
        } finally {
            setUploadingFile(false);
        }
    }, [id]);

    const { getRootProps: getSongFileRoot, getInputProps: getSongFileInput, isDragActive: isSongFileDrag } = useDropzone({
        onDrop: onSongFileDrop,
        accept: { 'audio/*': ['.mp3', '.flac', '.wav', '.ogg', '.m4a'] }
    });


    useEffect(() => {
        fetchItem();
        if (type === 'albums') {
            fetchAlbumSongs();
        }
        if (type === 'songs') {
            fetchSongFiles();
        }
        setCoverFile(null); // Reset cover on id change
        setStagedSongs([]);
        setGlobalArtists([]);
        setSongFiles([]);
    }, [type, id]);

    const fetchItem = async () => {
        setLoading(true);
        setError(null);
        try {
            let endpoint = '';
            if (type === 'songs') endpoint = `/songs/${id}`;
            else if (type === 'albums') endpoint = `/albums/${id}`;
            else if (type === 'artists') endpoint = `/artists/${id}`;
            else if (type === 'playlists') endpoint = `/playlists/${id}`;

            const res = await api.get(endpoint);
            const d = res.data;

            // Initialize form data
            if (type === 'songs') {
                setFormData({
                    title: d.title,
                    album: d.album ? { id: d.album.id, name: d.album.title } : null,
                    artists: d.artists ? d.artists.map(a => ({
                        id: a.id,
                        name: a.name,
                        identifier: a.identifiers?.[0]?.identifier // Best effort
                    })) : []
                });
            } else if (type === 'albums') {
                setFormData({ title: d.title });
            } else if (type === 'artists') {
                setFormData({ name: d.name });
            } else if (type === 'playlists') {
                setFormData({ name: d.name });
            }
        } catch (e) {
            console.error(e);
            setError("Failed to load item. " + (e.response?.data?.error || e.message));
        } finally {
            setLoading(false);
        }
    };

    const fetchAlbumSongs = async () => {
        try {
            const res = await api.get(`/albums/${id}/songs`);
            setExistingSongs(res.data.songs || []);
        } catch (e) {
            console.error("Failed to fetch album songs", e);
        }
    };

    const fetchSongFiles = async () => {
        try {
            const res = await api.get(`/songs/${id}/files`);
            setSongFiles(res.data || []);
        } catch (e) {
            console.error("Failed to fetch song files", e);
        }
    };

    const handleDeleteSongFile = async (fileId) => {
        if (!window.confirm("Delete this audio file?")) return;
        try {
            await api.delete(`/songs/files/${fileId}`);
            fetchSongFiles();
        } catch (e) {
            console.error(e);
            alert("Failed to delete file");
        }
    };

    const handleSave = async () => {
        setSaving(true);
        try {
            let endpoint = '';
            let payload = {};

            if (type === 'songs') {
                endpoint = `/songs/${id}`;

                const artists = (formData.artists || []).map(a => ({
                    name: a.name,
                    identifier: a.identifier || a.sub || (a.name ? a.name.toLowerCase().replace(/[^\w\s-]/g, '').trim().replace(/\s+/g, '-') : 'unknown')
                }));

                payload = {
                    title: formData.title,
                    album_title: formData.album?.name || '',
                    artists: artists
                };
            } else if (type === 'albums') {
                endpoint = `/albums/${id}`;
                payload = { title: formData.title };

                // Handle Cover Upload
                if (coverFile) {
                    const formDataVideo = new FormData();
                    formDataVideo.append('cover', coverFile);
                    await api.post(`/albums/covers/${id}`, formDataVideo, {
                        headers: { 'Content-Type': 'multipart/form-data' }
                    });
                }
            } else if (type === 'artists') {
                endpoint = `/artists/${id}`;
                payload = { name: formData.name };
            } else if (type === 'playlists') {
                endpoint = `/playlists/${id}`; // Global endpoint
                payload = { name: formData.name };
            }

            await api.put(endpoint, payload);
            if (type !== 'albums') navigate(-1); // Don't navigate back for albums, stay to manage songs
            else alert("Album details updated!");

        } catch (e) {
            console.error(e);
            alert("Failed to save: " + (e.response?.data?.error || e.message));
        } finally {
            setSaving(false);
        }
    };

    const handleDelete = async () => {
        if (!window.confirm("Are you sure you want to delete this item? This action cannot be undone.")) return;

        setSaving(true);
        try {
            let endpoint = `/${type}/${id}`;
            if (type === 'songs') endpoint = `/songs/${id}`;
            if (type === 'playlists') endpoint = `/playlists/${id}`;

            await api.delete(endpoint);
            navigate(-1);
        } catch (e) {
            console.error(e);
            alert("Failed to delete: " + (e.response?.data?.error || e.message));
            setSaving(false);
        }
    };

    // Album Songs Logic
    const handleGlobalArtistsChange = (newArtists) => {
        setGlobalArtists(newArtists);
        setStagedSongs(prev => prev.map(s => ({ ...s, artists: newArtists })));
    };

    const updateStagedSong = (index, updates) => {
        setStagedSongs(prev => {
            const newSongs = [...prev];
            newSongs[index] = { ...newSongs[index], ...updates };
            return newSongs;
        });
    };

    const removeStagedSong = (index) => {
        setStagedSongs(prev => prev.filter((_, i) => i !== index));
    };

    const handleUploadStagedSongs = async () => {
        setUploading(true);
        setUploadProgress({ current: 0, total: stagedSongs.length });

        const songsToUpload = stagedSongs.map((s, i) => ({ ...s, originalIndex: i })).filter(s => s.status !== 'success');

        for (let i = 0; i < songsToUpload.length; i++) {
            const songData = songsToUpload[i];
            const index = songData.originalIndex;

            try {
                if (songData.artists.length === 0) throw new Error("No artists selected");

                // 1. Create Song Metadata
                const songPayload = {
                    title: songData.title,
                    artists: songData.artists.map(a => ({ name: a.name, id: a.identifier })),
                    album_id: id,
                    album_title: "ignored"
                };
                const res = await api.post('/songs', songPayload);
                const songId = res.data.song.id;

                // 2. Upload File
                const formData = new FormData();
                formData.append('song_id', songId);
                formData.append('file', songData.file);

                await api.post('/songs/assign-file', formData, {
                    headers: { 'Content-Type': 'multipart/form-data' }
                });

                updateStagedSong(index, { status: 'success' });
            } catch (error) {
                console.error(`Failed song ${index}`, error);
                updateStagedSong(index, { status: 'error', error: error.message || "Failed" });
            }

            setUploadProgress(prev => ({ ...prev, current: prev.current + 1 }));
        }

        setUploading(false);
        fetchAlbumSongs(); // Refresh existing songs list
    };

    const handleDeleteExistingSong = async (songId) => {
        if (!window.confirm("Delete this song?")) return;
        try {
            await api.delete(`/songs/${songId}`);
            fetchAlbumSongs();
        } catch (e) {
            alert("Failed to delete song");
        }
    };

    if (loading) return (
        <div className="flex h-full items-center justify-center text-primary">
            <Loader className="animate-spin w-8 h-8" />
        </div>
    );

    if (error) return (
        <div className="p-10 text-center">
            <h2 className="text-red-500 mb-4 font-bold">Error</h2>
            <p className="text-white/60 mb-6">{error}</p>
            <button onClick={() => navigate(-1)} className="px-4 py-2 bg-white/10 hover:bg-white/20 text-white rounded">
                Go Back
            </button>
        </div>
    );

    const getIcon = () => {
        if (type === 'songs') return Music;
        if (type === 'albums') return Database;
        if (type === 'artists') return Mic;
        return Database;
    };
    const Icon = getIcon();

    return (
        <main className="flex-1 overflow-auto grid-bg p-6 flex flex-col gap-6 animate-slide-in">
            <div className="flex items-center gap-4 border-b border-white/10 pb-6">
                <button onClick={() => navigate(-1)} className="p-2 hover:bg-white/10 rounded-full transition-colors text-white/60 hover:text-white">
                    <ArrowLeft className="w-5 h-5" />
                </button>
                <div>
                    <h2 className="text-2xl font-bold uppercase tracking-widest text-primary flex items-center gap-3">
                        <Icon className="w-6 h-6 text-primary" /> Edit {type.slice(0, -1).toUpperCase()}
                    </h2>
                    <p className="text-[10px] uppercase font-mono tracking-wider opacity-60 mt-1">ID: {id}</p>
                </div>
            </div>

            <div className="max-w-4xl flex flex-col gap-8">
                {/* Dynamic Form */}
                <div className="flex flex-col gap-6 p-6 bg-black/20 border border-white/5 rounded-lg">
                    {type === 'songs' && (
                        <>
                            <div className="flex flex-col gap-2">
                                <label className="text-xs font-bold text-white/60 uppercase tracking-widest">Title</label>
                                <input
                                    className="bg-black/40 border border-white/10 p-3 text-white focus:border-primary outline-none transition-colors"
                                    value={formData.title || ''}
                                    onChange={e => setFormData({ ...formData, title: e.target.value })}
                                />
                            </div>
                            <SearchableSelect
                                label="Album"
                                type="album"
                                value={formData.album}
                                onChange={val => setFormData({ ...formData, album: val })}
                                placeholder="Search for album..."
                            />
                            <SearchableSelect
                                label="Artists"
                                type="artist"
                                multiple={true}
                                value={formData.artists}
                                onChange={val => setFormData({ ...formData, artists: val })}
                                placeholder="Search and select artists..."
                            />
                        </>
                    )}

                    {(type === 'albums' || type === 'artists' || type === 'playlists') && (
                        <div className="flex flex-col gap-2">
                            <label className="text-xs font-bold text-white/60 uppercase tracking-widest">Name/Title</label>
                            <input
                                className="bg-black/40 border border-white/10 p-3 text-white focus:border-primary outline-none transition-colors"
                                value={formData.title || formData.name || ''}
                                onChange={e => setFormData({ ...formData, title: e.target.value, name: e.target.value })}
                            />
                        </div>
                    )}

                    {/* Album Cover Upload */}
                    {type === 'albums' && (
                        <div className="flex flex-col gap-2">
                            <label className="text-xs font-bold text-white/60 uppercase tracking-widest">Cover Art</label>
                            <div className="flex flex-row gap-4 items-stretch">
                                {/* Current Cover Preview */}
                                <div className="flex-shrink-0">
                                    <img
                                        src={`/api/images/covers/${id}/lq?${Date.now()}`}
                                        alt="Current Cover"
                                        className="w-24 h-24 object-cover border border-white/10"
                                        onError={(e) => e.target.style.display = 'none'}
                                    />
                                </div>

                                <div
                                    {...getCoverRoot()}
                                    className={`border-2 border-dashed p-4 text-center cursor-pointer transition-colors flex-1 flex items-center justify-center
                                    ${isCoverDrag ? 'border-primary bg-primary/10' : 'border-white/10 hover:border-primary/50'}
                                    ${coverFile ? 'border-primary text-primary' : 'text-white/40'}
                                `}
                                >
                                    <input {...getCoverInput()} />
                                    {coverFile ? (
                                        <div className="flex items-center justify-center gap-2 font-bold text-xs uppercase tracking-tight">
                                            <Upload className="h-4 w-4" />
                                            <span className="truncate max-w-[120px]">{coverFile.name}</span>
                                            <button
                                                type="button"
                                                onClick={(e) => { e.stopPropagation(); setCoverFile(null); }}
                                                className="ml-2 p-1 hover:bg-white/10 rounded-full"
                                            >
                                                <X className="h-4 w-4 text-red-500" />
                                            </button>
                                        </div>
                                    ) : (
                                        <div className="text-[10px] font-mono uppercase tracking-wider">
                                            <p>Drop new cover here</p>
                                            <p className="opacity-50 mt-1">.JPG ONLY</p>
                                        </div>
                                    )}
                                </div>
                            </div>
                        </div>
                    )}

                    {/* Actions */}
                    <div className="flex items-center justify-between pt-6 border-t border-white/10">
                        <button
                            onClick={handleDelete}
                            disabled={saving}
                            className="px-6 py-3 bg-red-500/10 text-red-500 font-bold text-xs tracking-widest flex items-center gap-2 hover:bg-red-500/20 disabled:opacity-50 transition-colors"
                        >
                            <Trash2 className="w-4 h-4" /> DELETE {type.slice(0, -1).toUpperCase()}
                        </button>
                        <button
                            onClick={handleSave}
                            disabled={saving}
                            className="px-8 py-3 bg-primary text-black font-bold text-xs tracking-widest flex items-center gap-2 hover:opacity-90 disabled:opacity-50 shadow-lg shadow-primary/20 transition-all"
                        >
                            {saving ? <Loader className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />} SAVE CHANGES
                        </button>
                    </div>
                </div>

                {/* Album Songs Management */}
                {type === 'albums' && (
                    <div className="flex flex-col gap-6">
                        <h3 className="text-lg font-bold uppercase tracking-widest text-primary border-b border-primary/20 pb-2">Manage Songs</h3>


                        {/* Existing Songs List */}
                        <div className="p-6 bg-black/20 border border-white/5 rounded-lg">
                            <h4 className="text-sm font-bold text-white/80 mb-4">Existing Songs ({existingSongs.length})</h4>
                            <div className="space-y-1">
                                {existingSongs.map((song) => (
                                    <div key={song.id} className="flex items-center justify-between p-3 bg-white/5 rounded border border-white/5 hover:border-primary/30 transition-colors group">
                                        <div className="flex items-center gap-3">
                                            <Music className="w-4 h-4 text-primary/60" />
                                            <div>
                                                <div className="text-sm font-medium text-white">{song.title}</div>
                                                <div className="text-xs text-white/40">
                                                    {song.artists?.map(a => a.name).join(', ')}
                                                </div>
                                            </div>
                                        </div>
                                        <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                            <Button
                                                variant="ghost"
                                                size="sm"
                                                onClick={() => navigate(`/edit/songs/${song.id}`)}
                                                className="h-8 w-8 p-0"
                                            >
                                                <span className="sr-only">Edit</span>
                                                <Database className="h-4 w-4" />
                                            </Button>
                                            <Button
                                                variant="ghost"
                                                size="sm"
                                                onClick={() => handleDeleteExistingSong(song.id)}
                                                className="h-8 w-8 p-0 text-red-500 hover:text-red-400 hover:bg-red-500/10"
                                            >
                                                <Trash2 className="h-4 w-4" />
                                            </Button>
                                        </div>
                                    </div>
                                ))}
                                {existingSongs.length === 0 && <div className="text-white/30 text-xs italic text-center py-4">No songs in this album.</div>}
                            </div>
                        </div>

                        {/* Staged Songs Uploader */}
                        <div className="p-6 bg-black/20 border border-white/5 rounded-lg space-y-4">
                            <h4 className="text-sm font-bold text-white/80">Bulk Upload New Songs</h4>

                            <div className="bg-primary/5 p-4 rounded border border-primary/10">
                                <Label className="text-xs mb-2 block font-bold text-primary">GLOBAL ARTIST OVERRIDE</Label>
                                <ArtistPicker selectedArtists={globalArtists} onArtistsChange={handleGlobalArtistsChange} />
                                <p className="text-[10px] text-muted-foreground mt-2">* Selection applies to all staged songs below.</p>
                            </div>

                            <div
                                {...getSongsRoot()}
                                className={`border-2 border-dashed p-6 text-center cursor-pointer transition-colors flex flex-col items-center justify-center
                                    ${isSongsDrag ? 'border-primary bg-primary/10' : 'border-white/10 hover:border-primary/50'}
                                `}
                            >
                                <input {...getSongsInput()} />
                                <div className="text-white/40 text-[10px] font-mono uppercase tracking-wider">
                                    <Upload className="mx-auto h-5 w-5 mb-2 opacity-50" />
                                    <p>Drag & drop multiple audio files here</p>
                                    <p className="opacity-50 mt-1 text-[9px]">MP3, FLAC, WAV, OGG, M4A</p>
                                </div>
                            </div>

                            {stagedSongs.length > 0 && (
                                <div className="space-y-2 max-h-[300px] overflow-y-auto pr-2 custom-scrollbar">
                                    {stagedSongs.map((song, idx) => (
                                        <div key={idx} className={`p-3 border rounded grid grid-cols-12 gap-4 items-center ${song.status === 'error' ? 'border-destructive/50 bg-destructive/10' : 'border-white/10'}`}>
                                            <div className="col-span-4 space-y-1">
                                                <Label className="text-[10px] text-muted-foreground">Title</Label>
                                                <Input
                                                    value={song.title}
                                                    onChange={(e) => updateStagedSong(idx, { title: e.target.value })}
                                                    className="h-8 text-xs bg-black/20 border-white/10"
                                                    placeholder="Song Title"
                                                />
                                            </div>
                                            <div className="col-span-7 space-y-1">
                                                <Label className="text-[10px] text-muted-foreground">Artists</Label>
                                                <ArtistPicker
                                                    selectedArtists={song.artists}
                                                    onArtistsChange={(newArtists) => updateStagedSong(idx, { artists: newArtists })}
                                                />
                                            </div>
                                            <div className="col-span-1 flex flex-col items-center justify-center gap-1">
                                                {song.status === 'success' && <Check className="h-5 w-5 text-primary" />}
                                                {song.status === 'error' && <X className="h-5 w-5 text-destructive" title={song.error} />}
                                                {song.status === 'pending' && (
                                                    <Button variant="ghost" size="icon" className="h-6 w-6" onClick={() => removeStagedSong(idx)}>
                                                        <X className="h-4 w-4" />
                                                    </Button>
                                                )}
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            )}

                            {stagedSongs.length > 0 && (
                                <div className="flex justify-end gap-2">
                                    {uploading && (
                                        <div className="text-xs text-muted-foreground self-center mr-4">
                                            Uploading {uploadProgress.current} / {uploadProgress.total}
                                        </div>
                                    )}
                                    <Button onClick={handleUploadStagedSongs} disabled={uploading} className="bg-primary text-black hover:opacity-90">
                                        {uploading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                                        Upload {stagedSongs.filter(s => s.status !== 'success').length} Songs
                                    </Button>
                                </div>
                            )}
                        </div>

                    </div>
                )}

                {/* Song Files Management (Type == songs) */}
                {type === 'songs' && (
                    <div className="flex flex-col gap-6">
                        <h3 className="text-lg font-bold uppercase tracking-widest text-primary border-b border-primary/20 pb-2">Audio Files</h3>

                        <div className="p-6 bg-black/20 border border-white/5 rounded-lg space-y-4">
                            {/* Existing Files */}
                            {songFiles.length > 0 ? (
                                <div className="space-y-2">
                                    {songFiles.map((file) => (
                                        <div key={file.id} className="flex items-center justify-between p-3 bg-white/5 rounded border border-white/5">
                                            <div className="flex items-center gap-4">
                                                <div className="h-10 w-10 bg-primary/10 rounded flex items-center justify-center text-primary font-bold text-xs uppercase">
                                                    {file.format}
                                                </div>
                                                <div>
                                                    <div className="text-sm font-bold text-white lowercase tracking-wider">.{file.format.toLowerCase()}</div>
                                                    <div className="text-[10px] text-white/40 font-mono lowercase">
                                                        {(file.duration / 1000).toFixed(1)}s • Added {new Date(file.created_at).toLocaleDateString()}
                                                    </div>
                                                </div>
                                            </div>
                                            <div className="flex items-center gap-2">
                                                <a href={`/api/songs/download/${file.id}`} target="_blank" rel="noreferrer" className="p-2 hover:bg-white/10 rounded text-white/60 hover:text-primary transition-colors">
                                                    <Upload className="h-4 w-4 rotate-180" />
                                                </a>
                                                <button
                                                    onClick={() => handleDeleteSongFile(file.id)}
                                                    className="p-2 hover:bg-red-500/10 rounded text-white/60 hover:text-red-500 transition-colors"
                                                >
                                                    <Trash2 className="h-4 w-4" />
                                                </button>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            ) : (
                                <div className="text-center py-8 text-white/30 text-sm italic border-2 border-dashed border-white/5 rounded">
                                    No audio files uploaded yet.
                                </div>
                            )}

                            {/* Upload Area */}
                            <div className="pt-4 border-t border-white/5">
                                <Label className="text-xs mb-2 block font-bold text-white/60 uppercase tracking-widest">Add Audio File (Quality Variant)</Label>
                                <div
                                    {...getSongFileRoot()}
                                    className={`border-2 border-dashed p-6 text-center cursor-pointer transition-colors flex flex-col items-center justify-center
                                        ${isSongFileDrag ? 'border-primary bg-primary/10' : 'border-white/10 hover:border-primary/50'}
                                    `}
                                >
                                    <input {...getSongFileInput()} />
                                    {uploadingFile ? (
                                        <div className="flex flex-col items-center gap-2 text-primary">
                                            <Loader2 className="h-6 w-6 animate-spin" />
                                            <p className="text-xs uppercase tracking-widest">Uploading...</p>
                                        </div>
                                    ) : (
                                        <div className="text-white/40 text-[10px] font-mono uppercase tracking-wider">
                                            <Upload className="mx-auto h-5 w-5 mb-2 opacity-50" />
                                            <p>Drag & drop audio file here</p>
                                            <p className="opacity-50 mt-1 text-[9px]">MP3, FLAC, WAV, OGG, M4A</p>
                                        </div>
                                    )}
                                </div>
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </main>
    );
};

export default EditItem;
