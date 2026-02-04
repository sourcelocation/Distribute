import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useLocation, Link, useNavigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './AuthContext';
import api from './api';
import { StatsProvider } from './StatsContext';
import Header from './components/Header';
import Sidebar from './components/Sidebar';
import Dashboard from './pages/Dashboard';
import Login from './pages/Login';
import Users from './pages/Users_impl';
import Settings from './pages/Settings';
import GenericDataView from './pages/GenericDataView';
import EditItem from './pages/EditItem';
import { CreateArtistButton, CreateSongButton, CreateAlbumButton } from './components/CreationDialogs';
import { Music, Database, Mic, PlayCircle } from 'lucide-react';

import SetupWizard from './pages/SetupWizard';

const SetupGuard = ({ children }) => {
  const [checking, setChecking] = React.useState(true);
  const location = useLocation();
  const navigate = useNavigate();

  React.useEffect(() => {
    const checkSetup = async () => {
      try {
        const res = await api.get('/setup/status');
        if (!res.data.setup_complete) {
          if (location.pathname !== '/setup') {
            window.location.href = '/setup'; // Force redirect to avoid loop issues with router
          }
        }
      } catch (e) {
        console.error("Failed to check setup status", e);
      } finally {
        setChecking(false);
      }
    };
    checkSetup();
  }, []);

  if (checking) return null; // Or a loader
  return children;
};

const AuthGuard = ({ children }) => {
  const { user, loading } = useAuth();
  const location = useLocation();

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen bg-bg-dark text-primary">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return children;
};

const MainLayout = () => {
  return (
    <div className="flex h-screen bg-bg-dark text-text-primary overflow-hidden selection:bg-primary/30 font-sans">
      <Sidebar />
      <div className="flex-1 flex flex-col min-w-0 bg-gradient-to-br from-bg-dark to-bg-dark/95 relative">
        <div className="absolute inset-0 bg-[url('https://grainy-gradients.vercel.app/noise.svg')] opacity-20 pointer-events-none mix-blend-overlay"></div>
        <div className="absolute inset-0 bg-gradient-to-t from-bg-dark via-transparent to-transparent opacity-80 pointer-events-none"></div>

        <Header />

        <main className="flex-1 overflow-auto p-6 relative z-10 custom-scrollbar">
          <Routes>
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/edit/:type/:id" element={<EditItem />} />
            <Route
              path="/songs"
              element={
                <GenericDataView
                  key="songs"
                  title="Songs"
                  endpoint="/songs"
                  columns={[
                    {
                      key: 'cover',
                      label: '',
                      render: (row) => (
                        <div className="w-10 h-10 bg-white/5 rounded overflow-hidden">
                          {row.album?.id && (
                            <img
                              src={`/api/images/covers/${row.album.id}/lq`}
                              alt={row.album?.title || 'Album Cover'}
                              className="w-full h-full object-cover"
                              onError={(e) => { e.target.style.display = 'none'; }}
                            />
                          )}
                        </div>
                      )
                    },
                    { key: 'title', label: 'Title' },
                    { key: 'album.title', label: 'Album' },
                    { key: 'created_at', label: 'Created' }
                  ]}
                  icon={Music}
                  createAction={(refresh) => <CreateSongButton onSuccess={refresh} />}
                  actions={(row) => (
                    <Link to={`/edit/songs/${row.id}`} className="text-white/40 hover:text-primary transition-colors font-mono text-xs tracking-wider">
                      EDIT
                    </Link>
                  )}
                />
              }
            />
            <Route
              path="/albums"
              element={
                <GenericDataView
                  key="albums"
                  title="Albums"
                  endpoint="/admin/albums"
                  columns={[
                    {
                      key: 'cover',
                      label: '',
                      render: (row) => (
                        <div className="w-10 h-10 bg-white/5 rounded overflow-hidden">
                          <img
                            src={`/api/images/covers/${row.id}/lq`}
                            alt={row.title}
                            className="w-full h-full object-cover"
                            onError={(e) => { e.target.style.display = 'none'; }}
                          />
                        </div>
                      )
                    },
                    { key: 'title', label: 'Title' },
                    { key: 'created_at', label: 'Created' }
                  ]}
                  icon={Database}
                  createAction={(refresh) => <CreateAlbumButton onSuccess={refresh} />}
                  actions={(row) => (
                    <Link to={`/edit/albums/${row.id}`} className="text-white/40 hover:text-primary transition-colors font-mono text-xs tracking-wider">
                      EDIT
                    </Link>
                  )}
                />
              }
            />
            <Route
              path="/artists"
              element={
                <GenericDataView
                  key="artists"
                  title="Artists"
                  endpoint="/admin/artists"
                  columns={[
                    { key: 'name', label: 'Name' },
                    { key: 'created_at', label: 'Created' }
                  ]}
                  icon={Mic}
                  createAction={(refresh) => <CreateArtistButton onSuccess={refresh} />}
                  actions={(row) => (
                    <Link to={`/edit/artists/${row.id}`} className="text-white/40 hover:text-primary transition-colors font-mono text-xs tracking-wider">
                      EDIT
                    </Link>
                  )}
                />
              }
            />
            <Route
              path="/playlists"
              element={

                <GenericDataView
                  key="playlists"
                  title="Playlists"
                  endpoint="/admin/playlists"
                  columns={[
                    { key: 'name', label: 'Name' },
                    { key: 'user.username', label: 'Owner' },
                    { key: 'created_at', label: 'Created' }
                  ]}
                  icon={PlayCircle}
                  actions={(row) => (
                    <Link to={`/edit/playlists/${row.id}`} className="text-white/40 hover:text-primary transition-colors font-mono text-xs tracking-wider">
                      EDIT
                    </Link>
                  )}
                />
              }
            />
            <Route path="/users" element={<Users />} />
            <Route path="/settings" element={<Settings />} />
            <Route path="*" element={<Navigate to="/dashboard" replace />} />
          </Routes>
        </main>
      </div>
    </div>
  );
};

const App = () => {
  return (
    <AuthProvider>
      <Router>
        <SetupGuard>
          <Routes>
            <Route path="/setup" element={<SetupWizard />} />
            <Route path="/login" element={<Login />} />
            <Route
              path="/*"
              element={
                <AuthGuard>
                  <StatsProvider>
                    <MainLayout />
                  </StatsProvider>
                </AuthGuard>
              }
            />
          </Routes>
        </SetupGuard>
      </Router>
    </AuthProvider>
  );
};

export default App;
