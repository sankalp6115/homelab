import React, { use, useEffect, useState } from 'react';
import { PlayerContext } from '../contexts/PlayerContext';
import '../styles/Settings.css';
import { buildApiUrl } from '../utils/api';

const Settings = () => {
  const { setPlaybackRate, playbackRate, isOnekoEnabled, setIsOnekoEnabled, apiBase, updateApiBase, wallpaper, updateWallpaper } = use(PlayerContext);
  const [isSpeedEnabled, setIsSpeedEnabled] = useState(false);
  const [wallpaperArray, setWallpaperArray] = useState([]);
  const [backendIp, setBackendIp] = useState(apiBase || '');
  const [isUploadingWallpaper, setIsUploadingWallpaper] = useState(false);
  const [uploadError, setUploadError] = useState('');

  useEffect(() => {
    const channel = new BroadcastChannel("music_channel");
    channel.onmessage = (event) => {
      const { action, value } = event.data;
      if (action === "toggleSpeedControl") setIsSpeedEnabled(value);
    };

    return () => channel.close();
  }, []);

  useEffect(() => {
    setBackendIp(apiBase || '');
  }, [apiBase]);

  const fetchWallpapers = async () => {
    try {
      const data = await fetch(buildApiUrl('/api/wallpaper'));
      const wallpaperData = await data.json();
      setWallpaperArray(wallpaperData);
    } catch (err) {
      console.error('Failed to fetch wallpapers:', err);
    }
  };

  useEffect(() => {
    fetchWallpapers();
  }, [apiBase]);

  const toggleOneko = () => {
    const newVal = !isOnekoEnabled;
    setIsOnekoEnabled(newVal);
    const channel = new BroadcastChannel("music_channel");
    channel.postMessage({ action: "toggleOneko", value: newVal });
    channel.close();
  };

  const handleWallpaperUpload = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const formData = new FormData();
    formData.append('file', file);

    setIsUploadingWallpaper(true);
    setUploadError('');
    try {
      const res = await fetch(buildApiUrl('/api/wallpaper/upload'), {
        method: 'POST',
        body: formData,
      });
      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.detail || 'Upload failed');
      }
      const newWallpaper = await res.json();
      await fetchWallpapers();
      const newUrl = buildApiUrl(`/api/wallpaper/${newWallpaper.filename}`);
      updateWallpaper(newUrl);
    } catch (err) {
      setUploadError(err.message || 'Failed to upload wallpaper');
    } finally {
      setIsUploadingWallpaper(false);
      e.target.value = '';
    }
  };

  return (
    <section className="settings-page">
      <h1 className="settings-title">Music Player Settings</h1>

      <div className="setting-card row-layout">
        <span className="setting-label">Oneko Cat:</span>
        <button
          type="button"
          onClick={toggleOneko}
          className={`setting-btn ${isOnekoEnabled ? 'setting-btn-danger' : 'setting-btn-primary'}`}
        >
          {isOnekoEnabled ? 'Disable Oneko' : 'Enable Oneko'}
        </button>
      </div>

      <div className="setting-card row-layout">
        <span className="backend_ip setting-label">Backend IP:</span>
        <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
          <input
            type="text"
            name="backend_ip"
            id="backend_ip"
            className='setting-input'
            value={backendIp}
            onChange={(e) => setBackendIp(e.target.value)}
            placeholder="http://localhost:8000"
          />
          <button type="button" className="setting-btn setting-btn-primary" onClick={() => updateApiBase(backendIp)}>
            Apply
          </button>
        </div>
      </div>

      <div className="setting-card row-layout">
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', width: '100%' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
        <span className="setting-label">Wallpaper</span>
            <label className="setting-btn setting-btn-primary" style={{ cursor: isUploadingWallpaper ? 'wait' : 'pointer' }}>
              {isUploadingWallpaper ? 'Uploading...' : 'Upload Wallpaper'}
              <input
                type="file"
                accept="image/png,image/jpeg,image/webp"
                onChange={handleWallpaperUpload}
                disabled={isUploadingWallpaper}
                style={{ display: 'none' }}
              />
            </label>
            {uploadError && <span style={{ color: '#ef4444', fontSize: '0.875rem' }}>{uploadError}</span>}
          </div>
          <div className="setting-slider">
            {wallpaperArray.map((item, index) => {
              const filename = typeof item === 'object' && item !== null ? item.filename : item;
              const imgUrl = buildApiUrl(`/api/wallpaper/${filename}`);
              return (
                <img
                  src={imgUrl}
                  key={index}
                  alt={typeof item === 'object' && item?.name ? item.name : filename}
                  className={`setting-wallpaper ${wallpaper === imgUrl ? 'active-wallpaper' : ''}`}
                  onClick={() => updateWallpaper(imgUrl)}
                  style={{ cursor: 'pointer' }}
                />
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
};

export default Settings;
