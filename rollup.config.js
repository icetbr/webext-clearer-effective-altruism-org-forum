import metablock from 'rollup-plugin-userscript-metablock';
import cleanup from 'rollup-plugin-cleanup';
import { nodeResolve } from '@rollup/plugin-node-resolve';
import manifest from './manifest.json';
import meta from './metablock.json';

// NEED full path because of https://github.com/rollup/rollup/issues/4251 ?
// import { cssToEsm } from '@icetbr/utils/rollup';
import { cssToEsm } from '../../node_modules/@icetbr/utils/src/rollup.js';

/**
 * @type {import('rollup').RollupOptions}
 */
export default {
    input: 'src/content.js',
    plugins: [
        nodeResolve(),
        cssToEsm(),
        cleanup({
            comments: 'none',
            maxEmptyLines: 1,
        }),
    ],
    treeshake: {
        moduleSideEffects: 'no-external', // fixes sort of a bug, where some imports will be kept even if not used; there are other ways to avoid this, like the commented external bellow
    },
    // external: ['util'],
    output: [
        { file: 'dist/content.js' },
        {
            file: `../userscripts/scripts/${meta.downloadURL.split('/').at(-1)}`,
            plugins: [
                metablock({
                    order: ['name', 'description', 'version', 'author', 'icon', 'include', 'license', 'namespace', 'updateURL', 'downloadURL', 'require'],
                    override: {
                        name: manifest.name,
                        version: manifest.version,
                        description: manifest.description,
                        author: manifest.author,
                        match: manifest.content_scripts[0]?.matches[0],
                        include: manifest.content_scripts[0].include_globs?.[0],
                    },
                }),
            ]
        },
    ],
};
