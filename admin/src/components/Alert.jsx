import React from 'react';
import { AlertCircle, CheckCircle, Info } from 'lucide-react';

const Alert = ({ type = 'info', message, className = '' }) => {
    if (!message) return null;

    const styles = {
        error: 'border-red-500/30 text-red-400 bg-red-500/10',
        success: 'border-primary/30 text-primary bg-primary/10', // Using primary (cyan usually) for success to match theme, or green? Theme seems to use primary for success in existing code ('border-primary/30').
        info: 'border-blue-500/30 text-blue-400 bg-blue-500/10'
    };

    // Existing code used primary for non-error. So I'll stick to primary for success/default to keep consistency, but I'll define them explicitly.
    // Actually, let's use the exact classes from Settings.jsx for consistency first.
    // Settings.jsx: "border-primary/30 text-primary bg-primary/10" (for success/info)

    const themeStyles = {
        error: 'border-red-500/30 text-red-400 bg-red-500/10',
        success: 'border-secondary/30 text-secondary bg-secondary/10', // using secondary or primary?
        primary: 'border-primary/30 text-primary bg-primary/10'
    };

    const activeStyle = themeStyles[type] || themeStyles.primary;

    const icons = {
        error: <AlertCircle className="w-4 h-4 shrink-0" />,
        success: <CheckCircle className="w-4 h-4 shrink-0" />,
        primary: <Info className="w-4 h-4 shrink-0" />
    };

    return (
        <div className={`mb-6 text-[10px] font-mono p-2 border flex items-center gap-2 ${activeStyle} ${className}`}>
            {icons[type] || icons.primary}
            <span className="break-all">{message}</span>
        </div>
    );
};

export default Alert;
