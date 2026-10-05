// @ts-check
import { defineConfig, fontProviders } from 'astro/config';
import starlight from '@astrojs/starlight';

import mermaid from 'astro-mermaid';
import catppuccin from "@catppuccin/starlight";

// https://astro.build/config
export default defineConfig({
	experimental: {
		fonts: [
			{
				provider: fontProviders.google(),
				name: "Victor Mono",
				cssVariable: "--font-victor-mono",
			},
			{
				provider: fontProviders.google(),
				name: "JetBrains Mono",
				cssVariable: "--font-jetbrains-mono",
			},
		],
	},
	integrations: [
		mermaid({
			theme: 'forest',
			autoTheme: true
		}),
		starlight({
			title: 'ukanrenix',
			social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/denful/ukanrenix' }
      ],
			sidebar: [
				{
					label: 'ukanrenix',
					items: [
						{ label: 'Overview', slug: 'overview' },
					],
				},
				{
					label: 'Understand',
					items: [
						{ label: 'μKanren in Nix', slug: 'explanation/ukanren' },
						{ label: 'Weighted Search', slug: 'explanation/semiring' },
						{ label: 'Constraint Rules', slug: 'explanation/chr' },
						{ label: 'Staged Evaluation', slug: 'explanation/staged' },
					],
				},
				{
					label: 'Guides',
					items: [
						{ label: 'Getting Started', slug: 'guides/getting-started' },
						{ label: 'Logic Synthesis', slug: 'guides/synthesis' },
						{ label: 'Gen Integration', slug: 'guides/gen-integration' },
					],
				},
				{
					label: 'Reference',
					items: [
						{ label: 'Core API', slug: 'reference/core' },
						{ label: 'Semiring', slug: 'reference/semiring' },
						{ label: 'CHR', slug: 'reference/chr' },
						{ label: 'Bank', slug: 'reference/bank' },
						{ label: 'LLM Oracle', slug: 'reference/llm-oracle' },
						{ label: 'Gen Integration', slug: 'reference/gen-integration' },
					],
				},
			],
			components: {
				Head: './src/components/Head.astro',
				Sidebar: './src/components/Sidebar.astro',
				Footer: './src/components/Footer.astro',
				SocialIcons: './src/components/SocialIcons.astro',
				PageSidebar: './src/components/PageSidebar.astro',
				Hero: './src/components/Hero.astro',
			},
			plugins: [
				catppuccin({
					dark: { flavor: "macchiato", accent: "mauve" },
					light: { flavor: "latte", accent: "mauve" },
				}),
			],
			editLink: {
				baseUrl: 'https://github.com/denful/ukanrenix/edit/main/docs/',
			},
			customCss: [
				'./src/styles/custom.css'
			],
		}),
	],
});
