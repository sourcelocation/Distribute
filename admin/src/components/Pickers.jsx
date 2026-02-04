import React, { useState, useEffect } from 'react'
import { Check, ChevronsUpDown, Search, X } from "lucide-react"
import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import {
    Command,
    CommandEmpty,
    CommandGroup,
    CommandInput,
    CommandItem,
    CommandList,
} from "@/components/ui/command"
import {
    Popover,
    PopoverContent,
    PopoverTrigger,
} from "@/components/ui/popover"
import { Badge } from "@/components/ui/badge"
import api from '../api'

// Generic Resource Picker using Backend Search
function ResourcePicker({ type, onSelect, placeholder, renderItem, value }) {
    const [open, setOpen] = useState(false)
    const [query, setQuery] = useState("")
    const [results, setResults] = useState([])
    const [loading, setLoading] = useState(false)

    useEffect(() => {
        const timer = setTimeout(() => {
            if (query.trim().length > 0) {
                setLoading(true)
                api.get('/search', { params: { q: query, type, limit: 10 } })
                    .then(res => {
                        setResults(res.data || [])
                    })
                    .catch(console.error)
                    .finally(() => setLoading(false))
            } else {
                setResults([])
            }
        }, 300)

        return () => clearTimeout(timer)
    }, [query, type])

    return (
        <Popover open={open} onOpenChange={setOpen}>
            <PopoverTrigger asChild>
                <Button
                    variant="outline"
                    role="combobox"
                    aria-expanded={open}
                    className="w-full justify-between"
                >
                    {value ? value : placeholder}
                    <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
                </Button>
            </PopoverTrigger>
            <PopoverContent className="w-[400px] p-0">
                <Command shouldFilter={false}>
                    <CommandInput
                        placeholder={`Search ${type}...`}
                        value={query}
                        onValueChange={setQuery}
                    />
                    <CommandList>
                        {loading && <div className="py-6 text-center text-sm text-muted-foreground">Searching...</div>}
                        {!loading && results.length === 0 && <CommandEmpty>No results found.</CommandEmpty>}
                        <CommandGroup>
                            {results.map((item) => (
                                <CommandItem
                                    key={item.id}
                                    value={item.id} // value required for internal key handling but we manage selection manually
                                    onSelect={() => {
                                        onSelect(item)
                                        setOpen(false)
                                    }}
                                >
                                    {renderItem ? renderItem(item) : item.title}
                                </CommandItem>
                            ))}
                        </CommandGroup>
                    </CommandList>
                </Command>
            </PopoverContent>
        </Popover>
    )
}

export function ArtistPicker({ selectedArtists, onArtistsChange }) {
    const addArtist = (item) => {
        const exists = selectedArtists.find(a => a.id === item.id)
        if (exists) return

        onArtistsChange([...selectedArtists, {
            name: item.title,
            id: item.id,
            // Use UUID as identifier since backend now supports it
            identifier: item.id
        }])
    }

    const removeArtist = (id) => {
        onArtistsChange(selectedArtists.filter(a => a.id !== id))
    }

    return (
        <div className="flex flex-col gap-2">
            <ResourcePicker
                type="artist"
                placeholder="Select artists..."
                onSelect={addArtist}
                renderItem={(item) => (
                    <div className="flex flex-col">
                        <span>{item.title}</span>
                        {item.sub && <span className="text-xs text-muted-foreground">{item.sub}</span>}
                    </div>
                )}
            />
            <div className="flex flex-wrap gap-2">
                {selectedArtists.map(artist => (
                    <Badge key={artist.id} variant="secondary" className="cursor-pointer hover:bg-destructive/20" onClick={() => removeArtist(artist.id)}>
                        {artist.name} <X className="ml-1 h-3 w-3" />
                    </Badge>
                ))}
            </div>
        </div>
    )
}

export function AlbumPicker({ value, onValueChange }) {
    const [selectedTitle, setSelectedTitle] = useState("")

    // If we have an ID but no title (initial load), fetch it
    useEffect(() => {
        if (value && !selectedTitle) {
            api.get(`/albums/${value}`)
                .then(res => setSelectedTitle(res.data.title))
                .catch(() => setSelectedTitle("Unknown Album"))
        } else if (!value) {
            setSelectedTitle("")
        }
    }, [value])

    return (
        <ResourcePicker
            type="album"
            placeholder="Select album..."
            value={selectedTitle}
            onSelect={(item) => {
                onValueChange(item.id)
                setSelectedTitle(item.title)
            }}
            renderItem={(item) => (
                <div className="flex flex-col">
                    <span>{item.title}</span>
                    {item.sub && <span className="text-xs text-muted-foreground">{item.sub}</span>}
                </div>
            )}
        />
    )
}
