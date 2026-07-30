#!/usr/bin/env node
/**
 * Reescribe las URLs de descarga del twig DownloadPrinterApp.html.twig para que
 * apunten a los binarios reales adjuntados a una release de FacturaScripts/fsprinter.
 *
 * Uso: node update-download-page.js <tag> <assetsFile> <twigPath>
 *   - tag:        tag de la release (ej. v1.4.0)
 *   - assetsFile: fichero de texto con un nombre de asset por línea
 *   - twigPath:   ruta al fichero .twig a modificar
 *
 * Cada enlace del twig se identifica por la extensión del fichero en su href
 * (.exe, .dmg, .deb, .rpm, .AppImage) y se sustituye por la URL del asset real
 * con la misma extensión, usando la base de releases de fsprinter.
 */

const fs = require('fs');

const [, , tag, assetsFile, twigPath] = process.argv;

if (!tag || !assetsFile || !twigPath) {
    console.error('Uso: node update-download-page.js <tag> <assetsFile> <twigPath>');
    process.exit(1);
}

const base = `https://github.com/FacturaScripts/fsprinter/releases/download/${tag}/`;

// Lista de assets reales de la release (un nombre por línea)
const assets = fs.readFileSync(assetsFile, 'utf8')
    .split('\n')
    .map(s => s.trim())
    .filter(Boolean);

// Devuelve el primer asset cuyo nombre termina en la extensión indicada.
// Si se indica mustInclude, exige además que el nombre contenga ese texto.
function findAsset(ext, mustInclude) {
    return assets.find(a => {
        const name = a.toLowerCase();
        if (!name.endsWith(ext.toLowerCase())) {
            return false;
        }
        return !mustInclude || name.includes(mustInclude.toLowerCase());
    });
}

let html = fs.readFileSync(twigPath, 'utf8');
let replacements = 0;

// Enlaces de descarga que aparecen en el twig. Para Windows hay dos .exe
// (instalable nsis "Setup" y portable); queremos siempre el instalable.
const extensions = [
    { ext: '.exe', mustInclude: 'Setup' },
    { ext: '.dmg' },
    { ext: '.deb' },
    { ext: '.rpm' },
    { ext: '.AppImage' },
];

for (const { ext, mustInclude } of extensions) {
    const asset = findAsset(ext, mustInclude);
    if (!asset) {
        console.warn(`Aviso: no se encontró ningún asset con extensión ${ext}`);
        continue;
    }

    // Sustituye cualquier href de descarga de release que termine en esta extensión
    const escExt = ext.replace('.', '\\.');
    const re = new RegExp(
        `href="https://github\\.com/[^"]+/releases/download/[^"]+${escExt}"`,
        'gi'
    );

    const url = base + encodeURIComponent(asset);
    const before = html;
    html = html.replace(re, `href="${url}"`);
    if (html !== before) {
        replacements++;
        console.log(`Actualizado enlace ${ext} -> ${url}`);
    } else {
        console.warn(`Aviso: no se encontró ningún enlace ${ext} en el twig`);
    }
}

if (replacements === 0) {
    console.error('Error: no se realizó ninguna sustitución de URL.');
    process.exit(1);
}

fs.writeFileSync(twigPath, html);
console.log(`Hecho: ${replacements} enlaces actualizados en ${twigPath}`);
