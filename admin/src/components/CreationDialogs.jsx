import React, { useState, useCallback } from 'react'
import { useDropzone } from 'react-dropzone'
import { Plus, Upload, X, Loader2, Check } from "lucide-react"
import { Button } from "@/components/ui/button"
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { ArtistPicker, AlbumPicker } from "./Pickers"
import api from '../api'
import { CornerBrackets } from './FUI'

export function CreateArtistButton({ onSuccess }) {
    const [open, setOpen] = useState(false)
    const [name, setName] = useState("")
    const [identifiers, setIdentifiers] = useState("")
    const [loading, setLoading] = useState(false)

    const handleSubmit = async (e) => {
        e.preventDefault()
        setLoading(true)
        try {
            const idList = identifiers.split(',').map(s => s.trim()).filter(Boolean)
            // If empty identifiers, backend might auto-generate or we can send name as identifier
            const payload = {
                name,
                identifiers: idList.length > 0 ? idList : [name.toLowerCase().replace(/\s+/g, '-')]
            }
            await api.post('/artists', payload)
            setOpen(false)
            setName("")
            setIdentifiers("")
            if (onSuccess) onSuccess()
        } catch (error) {
            console.error(error)
            alert("Failed to create artist")
        } finally {
            setLoading(false)
        }
    }

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <Button className="fui-btn-bg border border-primary/20 cursor-pointer">
                    <Plus className="mr-2 h-4 w-4" /> New Artist
                </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[425px]">
                <DialogHeader>
                    <DialogTitle>Create Artist</DialogTitle>
                    <DialogDescription>
                        Add a new artist to the database.
                    </DialogDescription>
                </DialogHeader>
                <form onSubmit={handleSubmit} className="grid gap-4 py-4">
                    <div className="grid grid-cols-4 items-center gap-4">
                        <Label htmlFor="name" className="text-right text-xs">
                            Name
                        </Label>
                        <Input
                            id="name"
                            value={name}
                            onChange={(e) => setName(e.target.value)}
                            className="col-span-3"
                            required
                        />
                    </div>
                    <div className="grid grid-cols-4 items-center gap-4">
                        <Label htmlFor="identifiers" className="text-right text-xs">
                            Aliases
                        </Label>
                        <Input
                            id="identifiers"
                            value={identifiers}
                            onChange={(e) => setIdentifiers(e.target.value)}
                            placeholder="comma, separated"
                            className="col-span-3"
                        />
                    </div>
                    <DialogFooter>
                        <Button type="submit" disabled={loading}>
                            {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                            Create
                        </Button>
                    </DialogFooter>
                </form>
            </DialogContent>
        </Dialog>
    )
}

import { useNavigate } from 'react-router-dom'

export function CreateAlbumButton({ onSuccess }) {
    const [open, setOpen] = useState(false)
    const [title, setTitle] = useState("")
    const [date, setDate] = useState("")
    const [coverFile, setCoverFile] = useState(null)
    const [loading, setLoading] = useState(false)
    const navigate = useNavigate()

    const onDrop = useCallback(acceptedFiles => {
        if (acceptedFiles.length > 0) {
            const file = acceptedFiles[0]
            const objectUrl = URL.createObjectURL(file)
            const img = new Image()
            img.src = objectUrl

            img.onload = () => {
                if (img.width !== img.height) {
                    alert(`Image must be 1x1 (square). Current dimensions: ${img.width}x${img.height}`)
                    URL.revokeObjectURL(objectUrl)
                    return
                }
                setCoverFile(file)
                URL.revokeObjectURL(objectUrl)
            }

            img.onerror = () => {
                alert("Failed to load image validation.")
                URL.revokeObjectURL(objectUrl)
            }
        }
    }, [])

    const { getRootProps, getInputProps, isDragActive } = useDropzone({
        onDrop,
        onDropRejected: (fileRejections) => {
            fileRejections.forEach((rejection) => {
                rejection.errors.forEach((error) => {
                    if (error.code === 'file-invalid-type') {
                        alert("Invalid file format. Only JPG/JPEG is allowed.")
                    } else {
                        alert(error.message)
                    }
                })
            })
        },
        maxFiles: 1,
        accept: {
            'image/jpeg': ['.jpg', '.jpeg'],
        }
    })

    const handleSubmit = async (e) => {
        e.preventDefault()
        setLoading(true)
        try {
            const res = await api.post('/albums', {
                title,
                release_date: date ? new Date(date).toISOString() : new Date().toISOString()
            })

            const newAlbumId = res.data.id

            if (coverFile) {
                const formData = new FormData()
                formData.append('cover', coverFile)
                await api.post(`/albums/covers/${newAlbumId}`, formData, {
                    headers: { 'Content-Type': 'multipart/form-data' }
                })
            }

            setOpen(false)
            setTitle("")
            setDate("")
            setCoverFile(null)
            if (onSuccess) onSuccess()

            // Redirect to album edit page
            navigate(`/edit/albums/${newAlbumId}`)

        } catch (error) {
            console.error(error)
            alert("Failed to create album: " + (error.response?.data?.error || error.message))
        } finally {
            setLoading(false)
        }
    }

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <Button className="fui-btn-bg border border-primary/20 cursor-pointer">
                    <Plus className="mr-2 h-4 w-4" /> New Album
                </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[500px]">
                <CornerBrackets />
                <DialogHeader>
                    <DialogTitle>Create Album</DialogTitle>
                    <DialogDescription>
                        Create a new album shell. You will be redirected to add songs.
                    </DialogDescription>
                </DialogHeader>
                <form onSubmit={handleSubmit} className="grid gap-4 py-4">
                    <div className="grid grid-cols-4 items-center gap-4">
                        <Label htmlFor="title" className="text-right text-xs">
                            Title
                        </Label>
                        <Input
                            id="title"
                            value={title}
                            onChange={(e) => setTitle(e.target.value)}
                            className="col-span-3"
                            required
                        />
                    </div>
                    <div className="grid grid-cols-4 items-center gap-4">
                        <Label htmlFor="date" className="text-right text-xs">
                            Release Date
                        </Label>
                        <Input
                            id="date"
                            type="date"
                            value={date}
                            onChange={(e) => setDate(e.target.value)}
                            className="col-span-3"
                        />
                    </div>

                    <div className="grid grid-cols-4 items-start gap-4">
                        <Label className="text-right pt-2 text-xs">
                            Cover Art
                        </Label>
                        <div className="col-span-3">
                            <div
                                {...getRootProps()}
                                className={`border-2 border-dashed rounded-none p-4 text-center cursor-pointer transition-colors
                                    ${isDragActive ? 'border-primary bg-primary/10' : 'border-border hover:border-primary/50'}
                                    ${coverFile ? 'border-primary' : ''}
                                `}
                            >
                                <input {...getInputProps()} />
                                {coverFile ? (
                                    <div className="flex items-center justify-center gap-2 text-primary text-xs font-medium truncate">
                                        <Upload className="h-3 w-3 flex-shrink-0" />
                                        <span className="truncate">{coverFile.name}</span>
                                        <Button
                                            type="button"
                                            variant="ghost"
                                            size="sm"
                                            onClick={(e) => { e.stopPropagation(); setCoverFile(null); }}
                                            className="ml-auto h-6 w-6 p-0 hover:bg-destructive/20 hover:text-destructive"
                                        >
                                            <X className="h-3 w-3" />
                                        </Button>
                                    </div>
                                ) : (
                                    <div className="text-muted-foreground text-xs">
                                        <p>Click to select cover art</p>
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>

                    <DialogFooter>
                        <Button type="submit" disabled={loading}>
                            {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                            Create & Edit
                        </Button>
                    </DialogFooter>
                </form>
            </DialogContent>
        </Dialog>
    )
}


export function CreateSongButton({ onSuccess }) {
    const [open, setOpen] = useState(false)
    const [title, setTitle] = useState("")
    const [albumId, setAlbumId] = useState("")
    const [artists, setArtists] = useState([])
    const [file, setFile] = useState(null)
    const [loading, setLoading] = useState(false)

    const onDrop = useCallback(acceptedFiles => {
        if (acceptedFiles.length > 0) {
            setFile(acceptedFiles[0])
            // Auto-fill title from filename if empty
            if (!title) {
                const fname = acceptedFiles[0].name.replace(/\.[^/.]+$/, "")
                setTitle(fname)
            }
        }
    }, [title])

    const { getRootProps, getInputProps, isDragActive } = useDropzone({
        onDrop,
        maxFiles: 1,
        accept: {
            'audio/*': ['.mp3', '.flac', '.wav', '.ogg', '.m4a']
        }
    })

    const handleSubmit = async (e) => {
        e.preventDefault()
        if (!file) {
            alert("Please select a file")
            return
        }
        if (artists.length === 0) {
            alert("Please select at least one artist")
            return
        }
        if (!albumId) {
            alert("Please select an album") // Forced explicit album for now as per plan
            return
        }

        setLoading(true)
        try {
            // 1. Create Song Metadata
            const songPayload = {
                title,
                artists: artists.map(a => ({ name: a.name, id: a.identifier })), // API expects 'id' as identifier key based on SongCreationArtist struct json tag
                album_id: albumId,
                album_title: "ignored" // Backend handling
            }
            const res = await api.post('/songs', songPayload)
            const songId = res.data.song.id

            // 2. Upload File
            const formData = new FormData()
            formData.append('song_id', songId)
            formData.append('file', file)

            await api.post('/songs/assign-file', formData, {
                headers: { 'Content-Type': 'multipart/form-data' }
            })

            setOpen(false)
            // Reset form
            setTitle("")
            setAlbumId("")
            setArtists([])
            setFile(null)

            if (onSuccess) onSuccess()

        } catch (error) {
            console.error(error)
            alert("Failed to create song: " + (error.response?.data?.error || error.message))
        } finally {
            setLoading(false)
        }
    }

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <Button className="fui-btn-bg border border-primary/20 cursor-pointer">
                    <Plus className="mr-2 h-4 w-4" /> New Song
                </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[600px]">
                <CornerBrackets />
                <DialogHeader>
                    <DialogTitle>Create Song</DialogTitle>
                    <DialogDescription>
                        Upload a song and link it to an album and artists.
                    </DialogDescription>
                </DialogHeader>
                <form onSubmit={handleSubmit} className="grid gap-6 py-4">
                    <div className="grid grid-cols-4 items-center gap-4">
                        <Label htmlFor="song-title" className="text-right text-sm">
                            Title
                        </Label>
                        <Input
                            id="song-title"
                            value={title}
                            onChange={(e) => setTitle(e.target.value)}
                            className="col-span-3"
                            required
                        />
                    </div>

                    <div className="grid grid-cols-4 items-start gap-4">
                        <Label className="text-right pt-2 text-xs">
                            Artists
                        </Label>
                        <div className="col-span-3">
                            <ArtistPicker selectedArtists={artists} onArtistsChange={setArtists} />
                        </div>
                    </div>

                    <div className="grid grid-cols-4 items-center gap-4">
                        <Label className="text-right text-xs">
                            Album
                        </Label>
                        <div className="col-span-3">
                            <AlbumPicker value={albumId} onValueChange={setAlbumId} />
                        </div>
                    </div>

                    <div className="grid grid-cols-4 items-start gap-4">
                        <Label className="text-right pt-2 text-xs">
                            Audio File
                        </Label>
                        <div className="col-span-3">
                            <div
                                {...getRootProps()}
                                className={`border-2 border-dashed rounded-md p-6 text-center cursor-pointer transition-colors
                                    ${isDragActive ? 'border-primary bg-primary/10' : 'border-border hover:border-primary/50'}
                                    ${file ? 'border-primary' : ''}
                                `}
                            >
                                <input {...getInputProps()} />
                                {file ? (
                                    <div className="flex items-center justify-center gap-2 text-primary text-sm font-medium">
                                        <Upload className="h-4 w-4" />
                                        {file.name}
                                        <Button
                                            type="button"
                                            variant="ghost"
                                            size="sm"
                                            onClick={(e) => { e.stopPropagation(); setFile(null); }}
                                            className="ml-2 h-6 w-6 p-0 hover:bg-destructive/20 hover:text-destructive"
                                        >
                                            <X className="h-3 w-3" />
                                        </Button>
                                    </div>
                                ) : (
                                    <div className="text-muted-foreground text-sm">
                                        <Upload className="mx-auto h-8 w-8 mb-2 opacity-50" />
                                        <p>Drag & drop audio file here, or click to select</p>
                                        <p className="text-xs mt-1 opacity-50">.mp3, .flac, .wav, .m4a</p>
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>

                    <DialogFooter>
                        <Button type="submit" disabled={loading}>
                            {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                            Upload & Create
                        </Button>
                    </DialogFooter>
                </form>
            </DialogContent>
        </Dialog>
    )
}
