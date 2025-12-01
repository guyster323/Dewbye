import { useState, useEffect } from 'react';
import { Header } from './components/Header';
import { LocationInput } from './components/LocationInput';
import { VulnerabilityChart } from './components/VulnerabilityChart';
import { CondensationAnimation } from './components/CondensationAnimation';
import { BackgroundSlideshow } from './components/BackgroundSlideshow';
import { AnalysisResults } from './components/AnalysisResults';

export default function App() {
  const [darkMode, setDarkMode] = useState(true);
  const [location, setLocation] = useState('Current Location');
  const [dateRange, setDateRange] = useState({
    start: new Date().toISOString().split('T')[0],
    end: new Date().toISOString().split('T')[0]
  });
  const [showResults, setShowResults] = useState(false);

  useEffect(() => {
    if (darkMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [darkMode]);

  const handleAnalyze = () => {
    setShowResults(true);
  };

  return (
    <div className="min-h-screen relative overflow-x-hidden">
      <BackgroundSlideshow location={location} />
      
      {/* Glassmorphism overlay */}
      <div className="fixed inset-0 bg-white/30 dark:bg-slate-950/50 backdrop-blur-sm -z-5"></div>
      
      <Header darkMode={darkMode} setDarkMode={setDarkMode} />
      
      <main className="container mx-auto px-4 py-6 max-w-6xl relative z-10">
        {!showResults ? (
          <>
            {/* Top Section - Condensation Animation */}
            <CondensationAnimation />

            {/* Middle Section - Input Widgets */}
            <LocationInput 
              location={location}
              setLocation={setLocation}
              dateRange={dateRange}
              setDateRange={setDateRange}
              onAnalyze={handleAnalyze}
            />

            {/* Bottom Section - Today's Preview */}
            <VulnerabilityChart 
              location={location}
              date={dateRange.start}
              isPreview={true}
            />
          </>
        ) : (
          <AnalysisResults
            location={location}
            dateRange={dateRange}
            onBack={() => setShowResults(false)}
          />
        )}
      </main>
    </div>
  );
}