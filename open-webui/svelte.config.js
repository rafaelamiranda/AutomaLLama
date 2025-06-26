import adapter from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/kit/vite';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	preprocess: vitePreprocess(),

	kit: {
		adapter: adapter({
			pages: 'build',
			assets: 'build',
			fallback: undefined,
			precompress: false,
			strict: true
		}),
		
		// CORREÇÃO: Configurar paths para subdiretório
		paths: {
			base: process.env.VITE_BASE_URL?.replace(/\/$/, '') || '/open-webui',
			assets: process.env.VITE_BASE_URL || '/open-webui/'
		},
		
		// CORREÇÃO: Configurar para deployment em subpath
		trailingSlash: 'never'
	}
};

export default config;