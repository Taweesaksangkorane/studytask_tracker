import React from 'react';
import { motion } from 'motion/react';
import { 
  CheckCircle, 
  Calendar, 
  Clock, 
  ArrowRight,
  BellRing,
  BookOpen,
  House,
  GraduationCap,
  RefreshCw,
  LayoutGrid,
  Send,
  Settings,
  Lock,
  UploadCloud,
  FileText,
  ExternalLink
} from 'lucide-react';

const WEBAPP_URL = 'https://studytask-tracker-bbfb3.web.app';

export default function App() {
  return (
    <div className="min-h-screen bg-white text-neutral-900 font-sans selection:bg-blue-500/30">
      {/* Background decoration - Fixed blurred shapes */}
      <div className="fixed top-0 left-0 w-full h-full pointer-events-none overflow-hidden z-0">
        {/* Top right - Large blue blob */}
        <div className="absolute -top-20 -right-32 w-96 h-96 bg-blue-200 rounded-full blur-[120px] opacity-50"></div>
        {/* Top left - Indigo blob */}
        <div className="absolute top-0 -left-40 w-80 h-80 bg-indigo-200 rounded-full blur-[100px] opacity-40"></div>
        {/* Middle center - Small blue accent */}
        <div className="absolute top-1/3 left-1/3 w-60 h-60 bg-blue-100 rounded-full blur-[100px] opacity-30"></div>
        {/* Bottom right - Large gradient blob */}
        <div className="absolute -bottom-20 right-0 w-96 h-96 bg-gradient-to-tl from-blue-100 to-indigo-100 rounded-full blur-[120px] opacity-40"></div>
      </div>

      <div className="relative z-10">
      {/* Nav */}
      <nav className="fixed top-0 w-full bg-white/80 backdrop-blur-md z-50 border-b border-neutral-200/50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <a href="#home" className="flex items-center gap-2 hover:opacity-80 transition-opacity">
            <div className="w-8 h-8 bg-gradient-to-br from-blue-400 to-blue-600 rounded-lg flex items-center justify-center shadow-sm shadow-blue-500/30">
              <BookOpen className="w-5 h-5 text-white" />
            </div>
            <span className="font-bold text-lg tracking-tight text-neutral-900 hidden sm:inline">StudyTask</span>
          </a>
          <div className="hidden md:flex gap-8 text-sm font-medium text-neutral-600">
            <a href="#features" className="hover:text-blue-600 transition-colors">Features</a>
          </div>
          <div className="flex items-center gap-3">
            <a href={WEBAPP_URL} target="_blank" rel="noopener noreferrer" className="bg-blue-600 text-white px-6 py-2 rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors shadow-sm shadow-blue-600/20 cursor-pointer flex items-center gap-2">
              Open App <ExternalLink className="w-3.5 h-3.5" />
            </a>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="pt-32 pb-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto flex flex-col lg:flex-row items-center justify-between gap-16 min-h-[90vh]">
        <div className="lg:w-1/2 flex flex-col items-start text-left z-10">
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-blue-100/60 border border-blue-200 text-blue-700 text-xs font-semibold tracking-wide mb-6 shadow-sm"
          >
            <span className="w-2 h-2 rounded-full bg-blue-600 animate-pulse"></span>
            Academic Command Center
          </motion.div>
          
          <motion.h1 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1 }}
            className="text-5xl md:text-6xl font-bold tracking-tight text-neutral-900 leading-[1.15] mb-6"
          >
            Keep Every Study Task <br/>
            In One Place <br/>
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-500 to-blue-700">
              Synced from Classroom
            </span>
          </motion.h1>
          
          <motion.p 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            className="text-lg text-neutral-600 mb-8 max-w-lg leading-relaxed"
          >
            Track pending, submitted, and upcoming assignments in one clean dashboard. Get smart reminders and keep proof of submission organized.
          </motion.p>
          
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.3 }}
            className="flex flex-col sm:flex-row gap-4 w-full sm:w-auto"
          >
            <a href={WEBAPP_URL} target="_blank" rel="noopener noreferrer" className="bg-gradient-to-r from-blue-500 to-blue-600 text-white px-8 py-4 rounded-lg font-medium hover:shadow-lg hover:shadow-blue-500/30 transition-all flex items-center justify-center gap-2 cursor-pointer">
              Get Started for Free
              <ArrowRight className="w-4 h-4" />
            </a>
          </motion.div>
        </div>

        {/* Hero Interactive Mockup - Phone */}
        <motion.div 
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.7, delay: 0.2 }}
          className="lg:w-1/2 w-full flex justify-center relative"
        >
          {/* Decorative Gradient */}
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[400px] h-[400px] bg-gradient-to-br from-blue-300 to-blue-500 opacity-15 blur-[80px] rounded-full"></div>

          <div className="relative w-[360px] h-[720px] bg-white rounded-[2.5rem] shadow-2xl border-[10px] border-slate-900 mx-auto overflow-hidden flex flex-col z-10 selection:bg-transparent font-roboto">
            {/* Notch */}
            <div className="absolute top-0 inset-x-0 h-7 flex justify-center z-50">
              <div className="w-32 h-7 bg-slate-900 rounded-b-3xl"></div>
            </div>

            {/* Status Bar */}
            <div className="bg-slate-50 h-6 pt-1 px-4 flex items-center justify-between text-[10px] font-bold text-slate-800">
              <span>9:41</span>
              <div className="flex gap-1">
                <div className="w-3 h-3 rounded-full bg-slate-800"></div>
                <div className="w-3 h-3 rounded-full bg-slate-800"></div>
              </div>
            </div>

            {/* Home Screen Content */}
            <div className="flex-1 bg-gradient-to-b from-slate-50 to-white overflow-y-auto flex flex-col">
              
              {/* Header */}
              <div className="px-6 pt-6 pb-4">
                <div className="flex justify-between items-start mb-6">
                  <div>
                    <div className="text-[10px] font-bold text-blue-600 bg-blue-100 px-2 py-1 rounded inline-block mb-2">
                      STUDENT SPACE
                    </div>
                    <h1 className="text-[28px] leading-none font-bold text-[#1A1C2E]">Your Tasks</h1>
                  </div>
                  <div className="flex gap-2">
                    <button className="w-9 h-9 rounded-lg bg-white border border-slate-200 flex items-center justify-center shadow-sm">
                      <Calendar className="w-4 h-4 text-blue-600" />
                    </button>
                    <div className="w-9 h-9 rounded-full bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center text-white font-bold text-xs">
                      T
                    </div>
                  </div>
                </div>

                {/* Sync Card - Classroom Sync Bar */}
                <div className="bg-white p-4 rounded-3xl border border-slate-200 flex items-center justify-between shadow-sm">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-blue-600 flex items-center justify-center flex-shrink-0">
                      <GraduationCap className="w-5 h-5 text-white" />
                    </div>
                    <div className="min-w-0">
                      <div className="text-[14px] font-bold text-slate-900">Classroom Sync</div>
                      <div className="text-[10px] text-slate-500">UPDATED AT 14:32:45</div>
                    </div>
                  </div>
                  <motion.button 
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    className="px-5 py-2 bg-white border-2 border-slate-400 text-slate-700 text-[11px] font-bold rounded-full hover:bg-slate-50 transition-colors flex-shrink-0"
                  >
                    SYNC NOW
                  </motion.button>
                </div>
              </div>

            {/* Stats Cards */}
              <div className="px-6 pb-6 grid grid-cols-3 gap-3">
                {/* All - Featured */}
                <div className="bg-white border-2 border-blue-500 rounded-2xl p-4 text-center shadow-sm hover:shadow-md transition-shadow">
                  <LayoutGrid className="w-7 h-7 text-blue-500 mx-auto mb-2" />
                  <div className="text-2xl font-bold text-slate-900">29</div>
                </div>
                {/* Submitted */}
                <div className="bg-white border border-slate-200 rounded-2xl p-4 text-center shadow-sm hover:shadow-md transition-shadow">
                  <CheckCircle className="w-6 h-6 text-green-500 mx-auto mb-2" />
                  <div className="text-xs text-slate-600 font-semibold mb-1">Submitted</div>
                  <div className="text-2xl font-bold text-slate-900">23</div>
                </div>
                {/* Pending */}
                <div className="bg-white border border-slate-200 rounded-2xl p-4 text-center shadow-sm hover:shadow-md transition-shadow">
                  <Clock className="w-6 h-6 text-orange-500 mx-auto mb-2" />
                  <div className="text-xs text-slate-600 font-semibold mb-1">Pending</div>
                  <div className="text-2xl font-bold text-slate-900">6</div>
                </div>
              </div>

              {/* Latest Tasks Label */}
              <div className="px-6 pb-2">
                <div className="text-[12px] font-bold text-slate-500 tracking-[0.15em] uppercase">Latest Tasks</div>
              </div>

              {/* Task Cards */}
              <div className="px-6 pb-6 space-y-3">
                {/* Task 1 - Submitted (Green) */}
                <motion.div
                  whileHover={{ y: -2 }}
                  className="bg-white rounded-2xl p-4 border border-slate-200 border-l-4 border-l-green-500 shadow-sm hover:shadow-md transition-shadow"
                >
                  <div className="inline-block">
                    <span className="text-xs font-bold text-green-700 bg-green-100 px-2 py-1 rounded">SUBMITTED</span>
                  </div>
                  <div className="font-bold text-[18px] leading-tight text-slate-900 mt-2 mb-1">Class check-in</div>
                  <div className="text-[14px] text-slate-600 mb-2">1501115 Computer Engineering Essentials (1/2567)</div>
                  <div className="flex gap-3 text-xs text-blue-600 font-medium">
                    <span className="flex items-center gap-1"><Calendar className="w-3.5 h-3.5" /> 13/11/2024</span>
                    <span className="flex items-center gap-1"><Clock className="w-3.5 h-3.5" /> 05:30</span>
                  </div>
                </motion.div>

                {/* Task 2 - Submitted (Green) */}
                <motion.div
                  whileHover={{ y: -2 }}
                  className="bg-white rounded-2xl p-4 border border-slate-200 border-l-4 border-l-green-500 shadow-sm hover:shadow-md transition-shadow"
                >
                  <div className="inline-block">
                    <span className="text-xs font-bold text-green-700 bg-green-100 px-2 py-1 rounded">SUBMITTED</span>
                  </div>
                  <div className="font-bold text-[18px] leading-tight text-slate-900 mt-2 mb-1">Multiple choice exam (40 question)</div>
                  <div className="text-[14px] text-slate-600 mb-2">1501115 Computer Engineering Essentials (1/2567)</div>
                  <div className="flex gap-3 text-xs text-blue-600 font-medium">
                    <span className="flex items-center gap-1"><Calendar className="w-3.5 h-3.5" /> 17/11/2024</span>
                    <span className="flex items-center gap-1"><Clock className="w-3.5 h-3.5" /> 04:59</span>
                  </div>
                </motion.div>

                {/* Task 3 - Submitted (Green) */}
                <motion.div
                  whileHover={{ y: -2 }}
                  className="bg-white rounded-2xl p-4 border border-slate-200 border-l-4 border-l-green-500 shadow-sm hover:shadow-md transition-shadow"
                >
                  <div className="inline-block">
                    <span className="text-xs font-bold text-green-700 bg-green-100 px-2 py-1 rounded">SUBMITTED</span>
                  </div>
                  <div className="font-bold text-[18px] leading-tight text-slate-900 mt-2 mb-1">Research presentation</div>
                  <div className="text-[14px] text-slate-600 mb-2">1501115 Computer Engineering Essentials (1/2567)</div>
                  <div className="flex gap-3 text-xs text-blue-600 font-medium">
                    <span className="flex items-center gap-1"><Calendar className="w-3.5 h-3.5" /> 15/11/2024</span>
                    <span className="flex items-center gap-1"><Clock className="w-3.5 h-3.5" /> 10:15</span>
                  </div>
                </motion.div>
              </div>
            </div>

            {/* Bottom Navigation */}
            <div className="bg-white border-t border-slate-200 h-14 flex items-center justify-between px-6 relative">
              <button className="flex flex-col items-center gap-1">
                <House className="w-5 h-5 text-blue-600" />
                <span className="text-[10px] text-blue-600 font-semibold">Home</span>
              </button>
              
              {/* Center space for FAB */}
              <div className="w-12"></div>
              
              <button className="flex flex-col items-center gap-1">
                <Settings className="w-5 h-5 text-slate-400" />
                <span className="text-[10px] text-slate-500 font-semibold">Settings</span>
              </button>
            </div>

            {/* Floating Action Button - Centered at bottom */}
            <div className="absolute bottom-7 left-1/2 -translate-x-1/2 w-14 h-14 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full shadow-lg flex items-center justify-center z-20 border-4 border-white cursor-pointer hover:shadow-xl transition-shadow">
              <span className="text-white font-bold text-3xl leading-none">+</span>
            </div>
          </div>
        </motion.div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-24 bg-gradient-to-b from-white to-blue-50 border-t border-blue-100/50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-16">
            <h2 className="text-4xl sm:text-5xl font-bold tracking-tight text-neutral-900 mb-4">
              Features Built for Student Life
            </h2>
            <p className="text-neutral-600 text-lg">
              Every feature is crafted to solve real academic workflow pain points.
            </p>
          </div>
          
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            <FeatureCard 
              icon={<GraduationCap className="w-6 h-6" />}
              title="Classroom Sync"
              desc="Import classes, assignments, and deadlines from Google Classroom in one click."
              color="from-blue-500 to-blue-600"
            />
            <FeatureCard 
              icon={<LayoutGrid className="w-6 h-6" />}
              title="Organized Dashboard"
              desc="See all statuses in one view: pending, submitted, and closed tasks grouped by subject."
              color="from-indigo-500 to-indigo-600"
            />
            <FeatureCard 
              icon={<UploadCloud className="w-6 h-6" />}
              title="Upload Proof"
              desc="Attach PDFs, images, or Google Drive links as evidence for each submission."
              color="from-cyan-500 to-cyan-600"
            />
            <FeatureCard 
              icon={<BellRing className="w-6 h-6" />}
              title="Smart Reminders"
              desc="Set custom reminders such as 1 hour, 12 hours, or 1 day before deadlines."
              color="from-amber-500 to-amber-600"
            />
            <FeatureCard 
              icon={<FileText className="w-6 h-6" />}
              title="Manual Task Creation"
              desc="Add group projects and personal tasks beyond what comes from Classroom sync."
              color="from-teal-500 to-teal-600"
            />
            <FeatureCard 
              icon={<Lock className="w-6 h-6" />}
              title="Secure and Simple"
              desc="Sign in with Google and keep your data safely stored on Firebase."
              color="from-emerald-500 to-emerald-600"
            />
          </div>
        </div>
      </section>

      {/* How It Works Section */}
      <section className="py-24 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-16">
            <h2 className="text-4xl font-bold tracking-tight text-neutral-900 mb-4">
              Get Started in 3 Steps
            </h2>
            <p className="text-neutral-600 text-lg">
              Set everything up in under 2 minutes with your Google account.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5 }}
              viewport={{ once: true }}
              className="relative"
            >
              <div className="flex flex-col items-center">
                <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-blue-600 text-white rounded-full flex items-center justify-center font-bold text-2xl mb-4">
                  1
                </div>
                <h3 className="text-xl font-bold text-neutral-900 mb-3 text-center">Sign In with Google</h3>
                <p className="text-neutral-600 text-center">
                  Click "Open App" and choose your Google account.
                </p>
              </div>
              {/* Arrow line to next step */}
              <div className="hidden md:block absolute top-8 -right-8 w-16 h-0.5 bg-gradient-to-r from-blue-500 to-transparent"></div>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.1 }}
              viewport={{ once: true }}
              className="relative"
            >
              <div className="flex flex-col items-center">
                <div className="w-16 h-16 bg-gradient-to-br from-indigo-500 to-indigo-600 text-white rounded-full flex items-center justify-center font-bold text-2xl mb-4">
                  2
                </div>
                <h3 className="text-xl font-bold text-neutral-900 mb-3 text-center">Sync Classroom</h3>
                <p className="text-neutral-600 text-center">
                  Tap "SYNC" to import your classes and assignments.
                </p>
              </div>
              {/* Arrow line to next step */}
              <div className="hidden md:block absolute top-8 -right-8 w-16 h-0.5 bg-gradient-to-r from-indigo-500 to-transparent"></div>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.2 }}
              viewport={{ once: true }}
            >
              <div className="flex flex-col items-center">
                <div className="w-16 h-16 bg-gradient-to-br from-cyan-500 to-cyan-600 text-white rounded-full flex items-center justify-center font-bold text-2xl mb-4">
                  3
                </div>
                <h3 className="text-xl font-bold text-neutral-900 mb-3 text-center">Manage and Stay on Track</h3>
                <p className="text-neutral-600 text-center">
                  Set reminders for every task and track your progress.
                </p>
              </div>
            </motion.div>
          </div>
        </div>
      </section>
      <section className="py-24 bg-gradient-to-r from-blue-600 via-blue-500 to-indigo-600 text-white relative overflow-hidden">
        {/* Decorative shapes */}
        <div className="absolute top-0 right-0 w-[600px] h-[600px] bg-blue-400 rounded-full blur-[100px] -translate-y-1/2 translate-x-1/4 opacity-30"></div>
        <div className="absolute bottom-0 left-0 w-[400px] h-[400px] bg-indigo-400 rounded-full blur-[100px] translate-y-1/3 -translate-x-1/4 opacity-30"></div>

        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center relative z-10">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            viewport={{ once: true }}
            className="mx-auto w-20 h-20 bg-white/20 backdrop-blur-md rounded-2xl shadow-xl flex items-center justify-center mb-8 border border-white/30"
          >
            <BookOpen className="w-10 h-10 text-white" />
          </motion.div>
          <motion.h2 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1 }}
            viewport={{ once: true }}
            className="text-4xl md:text-5xl font-bold mb-6 tracking-tight"
          >
            Take Back Your Free Time
          </motion.h2>
          <motion.p 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            viewport={{ once: true }}
            className="text-blue-100 mb-10 text-lg lg:text-xl font-light max-w-2xl mx-auto"
          >
            Stop worrying about missed assignments or scattered deadlines. StudyTask Tracker keeps everything organized in one app.
          </motion.p>
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.3 }}
            viewport={{ once: true }}
            className="flex flex-col sm:flex-row items-center justify-center gap-4 flex-wrap"
          >
            <a href={WEBAPP_URL} target="_blank" rel="noopener noreferrer" className="bg-white text-blue-600 px-8 py-4 rounded-lg font-bold hover:bg-blue-50 transition-all shadow-xl cursor-pointer flex items-center gap-2">
              <img src="https://fonts.gstatic.com/s/i/productlogos/googleg/v6/24px.svg" alt="Google" className="w-5 h-5"/>
              Open App
            </a>
            <p className="text-sm text-blue-200 flex items-center gap-2 justify-center">
               <Lock className="w-4 h-4 text-blue-100"/> Secured with your Google Account
            </p>
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gradient-to-b from-slate-50 to-slate-100 border-t border-blue-100 text-neutral-700 py-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-12 mb-12">
            <div className="col-span-1 md:col-span-2 lg:col-span-1">
              <div className="flex items-center gap-2 mb-4">
                <div className="w-8 h-8 bg-gradient-to-br from-blue-400 to-blue-600 rounded-lg flex items-center justify-center">
                  <BookOpen className="w-5 h-5 text-white" />
                </div>
                <span className="font-bold text-lg text-neutral-900 tracking-tight">StudyTask</span>
              </div>
              <p className="text-sm max-w-sm leading-relaxed text-neutral-600">
                A study task tracking system designed for students to reduce chaos and stay consistently organized.
              </p>
            </div>
            <div>
              <h4 className="text-neutral-900 font-bold mb-4 text-sm uppercase tracking-wide">Features</h4>
              <ul className="space-y-2 text-sm flex flex-col">
                <a href="#" className="text-neutral-600 hover:text-blue-600 transition-colors">Classroom Sync</a>
                <a href="#" className="text-neutral-600 hover:text-blue-600 transition-colors">Manual Tasks</a>
                <a href="#" className="text-neutral-600 hover:text-blue-600 transition-colors">Smart Reminders</a>
                <a href="#" className="text-neutral-600 hover:text-blue-600 transition-colors">File Upload</a>
              </ul>
            </div>
            <div>
              <h4 className="text-neutral-900 font-bold mb-4 text-sm uppercase tracking-wide">Resources</h4>
              <ul className="space-y-2 text-sm flex flex-col">
                <a href="#" className="text-neutral-600 hover:text-blue-600 transition-colors">User Guide</a>
                <a href="#" className="text-neutral-600 hover:text-blue-600 transition-colors">FAQ</a>
                <a href="#" className="text-neutral-600 hover:text-blue-600 transition-colors">Contact Us</a>
              </ul>
            </div>
            <div>
              <h4 className="text-neutral-900 font-bold mb-4 text-sm uppercase tracking-wide">Links</h4>
              <ul className="space-y-2 text-sm flex flex-col">
                <a href={WEBAPP_URL} target="_blank" rel="noopener noreferrer" className="text-neutral-600 hover:text-blue-600 transition-colors flex items-center gap-1">
                  Web App <ExternalLink className="w-3 h-3" />
                </a>
                <a href="#" className="text-neutral-600 hover:text-blue-600 transition-colors">GitHub</a>
                <a href="#" className="text-neutral-600 hover:text-blue-600 transition-colors">Privacy Policy</a>
              </ul>
            </div>
          </div>
          
          <div className="border-t border-blue-100/50 pt-8 flex flex-col sm:flex-row justify-between items-center gap-4">
            <p className="text-sm text-neutral-500">© {new Date().getFullYear()} StudyTask Tracker. All rights reserved.</p>
            <div className="flex flex-wrap justify-center gap-6 text-sm">
              <a href="#" className="text-neutral-600 hover:text-blue-600 transition-colors">Privacy Policy</a>
              <a href="#" className="text-neutral-600 hover:text-blue-600 transition-colors">Terms of Use</a>
            </div>
          </div>
        </div>
      </footer>
      </div>
    </div>
  );
}

function FeatureCard({ icon, title, desc, color }: { icon: React.ReactNode, title: string, desc: string, color: string }) {
  return (
    <motion.div 
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      viewport={{ once: true }}
      className="p-8 rounded-2xl border border-blue-100 bg-white hover:border-blue-200 hover:shadow-xl hover:shadow-blue-500/10 transition-all duration-300 group"
    >
      <div className={`w-14 h-14 bg-gradient-to-br ${color} text-white rounded-xl flex items-center justify-center mb-6 shadow-lg group-hover:scale-110 transition-transform duration-300`}>
        {icon}
      </div>
      <h3 className="text-xl font-bold text-neutral-900 mb-3">{title}</h3>
      <p className="text-neutral-600 leading-relaxed text-sm">{desc}</p>
    </motion.div>
  )
}
