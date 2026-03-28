export default function Home() {
  return (
    <main className="relative min-h-screen overflow-hidden bg-slate-950 px-6 py-16 text-slate-100">
      <div className="pointer-events-none absolute inset-0">
        <div className="absolute -top-24 left-1/3 h-80 w-80 rounded-full bg-cyan-500/20 blur-3xl" />
        <div className="absolute right-0 top-1/3 h-96 w-96 rounded-full bg-indigo-500/20 blur-3xl" />
        <div className="absolute bottom-0 left-0 h-96 w-96 rounded-full bg-fuchsia-500/10 blur-3xl" />
      </div>

      <div className="relative mx-auto flex w-full max-w-6xl flex-col gap-10">
        <div className="inline-flex w-fit items-center gap-2 rounded-full border border-white/15 bg-white/5 px-3 py-1 text-xs font-medium tracking-[0.14em] text-cyan-200 uppercase">
          Live Demo Environment
        </div>

        <section className="rounded-3xl border border-white/10 bg-white/5 p-8 shadow-2xl shadow-black/40 backdrop-blur-xl sm:p-12">
          <p className="text-sm font-medium tracking-[0.18em] text-cyan-300 uppercase">
            Windsor / Vercel
          </p>
          <h1 className="mt-4 text-4xl font-semibold tracking-tight text-white sm:text-6xl">
            demo-wm37vl1m
          </h1>
          <p className="mt-5 max-w-3xl text-lg leading-relaxed text-slate-300">
            A production-style starter for validating project provisioning, Git
            integration, and deployment flow before shipping full product
            features.
          </p>

          <div className="mt-8 flex flex-wrap gap-3">
            <a
              href="https://nextjs.org/docs"
              target="_blank"
              rel="noopener noreferrer"
              className="rounded-full bg-cyan-400 px-5 py-2 text-sm font-semibold text-slate-950 transition hover:bg-cyan-300"
            >
              Next.js Docs
            </a>
            <a
              href="https://vercel.com/docs"
              target="_blank"
              rel="noopener noreferrer"
              className="rounded-full border border-white/20 bg-white/5 px-5 py-2 text-sm font-semibold text-slate-200 transition hover:bg-white/10"
            >
              Vercel Docs
            </a>
          </div>
        </section>

        <section className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <div className="rounded-2xl border border-white/10 bg-white/5 p-5 backdrop-blur">
            <p className="text-xs tracking-wide text-slate-400 uppercase">Framework</p>
            <p className="mt-2 text-lg font-semibold text-white">Next.js + TypeScript</p>
          </div>
          <div className="rounded-2xl border border-white/10 bg-white/5 p-5 backdrop-blur">
            <p className="text-xs tracking-wide text-slate-400 uppercase">Source Path</p>
            <p className="mt-2 text-lg font-semibold text-white">
              <code>demo/</code>
            </p>
          </div>
          <div className="rounded-2xl border border-white/10 bg-white/5 p-5 backdrop-blur">
            <p className="text-xs tracking-wide text-slate-400 uppercase">Repository</p>
            <p className="mt-2 text-lg font-semibold text-white">windsorcli/apps</p>
          </div>
          <div className="rounded-2xl border border-emerald-300/30 bg-emerald-300/10 p-5 backdrop-blur">
            <p className="text-xs tracking-wide text-emerald-200 uppercase">Status</p>
            <p className="mt-2 text-lg font-semibold text-emerald-100">
              Ready for Iteration
            </p>
          </div>
        </section>
      </div>
    </main>
  );
}
