#!/usr/bin/env node
/*
 * Turns a built blog post into a drawing sheet:
 *  - title block under the h1 (type, date, updated, reading time, sheet n / N)
 *  - table of contents (margin on wide screens, collapsible inline otherwise)
 *  - code blocks as numbered "details" with line numbers
 *
 * usage: node build/enhance-post.js <html file> <kind> <date> <updated> <sheet> <total>
 */
'use strict';

var fs = require('fs');

var args = process.argv.slice(2),
    file = args[0],
    kind = args[1] || '',
    date = args[2] || '',
    updated = args[3] || '',
    sheet = args[4] || '',
    total = args[5] || '';

var html = fs.readFileSync(file, 'utf8');

function escapeHtml(text) {
  return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function stripTags(text) {
  return text.replace(/<[^>]*>/g, ' ');
}

// posts are written in English, the site chrome stays German
html = html.replace('<html lang="de">', '<html lang="en">')
    .replace('<nav class="nav"', '<nav lang="de" class="nav"')
    .replace('<footer class="titleblock"', '<footer lang="de" class="titleblock"');

var mainOpen = html.match(/<main class="content content--text">/);
var mainClose = html.lastIndexOf('</main>');
if (!mainOpen || mainClose < 0) {
  process.exit(0);
}
var bodyStart = mainOpen.index + mainOpen[0].length;
var body = html.slice(bodyStart, mainClose);

// the type is shown in the title block, so drop "(DEV-TIP) " from the heading
body = body.replace(/(<h1[^>]*>)\s*\([^)]*\)\s*/, '$1');

// the date paragraph right after the heading moves into the title block
body = body.replace(/(<\/h1>\s*)<p>\s*\d{1,2}\.\d{1,2}\.\d{4}[^<]{0,40}<\/p>/, '$1');

// reading time at 200 words per minute
var words = stripTags(body).split(/\s+/).filter(Boolean).length,
    minutes = Math.max(1, Math.round(words / 200));

var cells = [];
if (kind) {
  cells.push(['Type', escapeHtml(kind)]);
}
if (date) {
  cells.push(['Date', escapeHtml(date)]);
}
if (updated) {
  cells.push(['Updated', escapeHtml(updated)]);
}
cells.push(['Reading time', minutes + ' min']);
if (sheet && total) {
  cells.push(['Sheet', sheet + ' / ' + total]);
}
var titleBlock = '<dl class="post-meta">' + cells.map(function (cell) {
  return '<div><dt>' + cell[0] + '</dt><dd>' + cell[1] + '</dd></div>';
}).join('') + '</dl>';

// table of contents from the h2 headings pandoc gave ids to
var headings = [],
    headingPattern = /<h2 id="([^"]+)"[^>]*>([\s\S]*?)<\/h2>/g,
    match;
while ((match = headingPattern.exec(body)) !== null) {
  headings.push({id: match[1], text: stripTags(match[2]).replace(/\s+/g, ' ').trim()});
}

function tocList() {
  return '<ol>' + headings.map(function (heading) {
    return '<li><a href="#' + heading.id + '">' + heading.text + '</a></li>';
  }).join('') + '</ol>';
}

var inlineToc = '',
    marginToc = '';
if (headings.length >= 2) {
  inlineToc = '<details class="toc toc--inline"><summary>Contents</summary>' +
      '<nav aria-label="Contents">' + tocList() + '</nav></details>';
  marginToc = '<aside class="post-margin"><nav class="toc toc--margin" aria-label="Contents">' +
      '<p class="toc__title">Contents</p>' + tocList() + '</nav>' +
      '<p class="toc__top"><a href="#top">Back to top</a></p></aside>';
}

body = body.replace(/<\/h1>/, '</h1>' + titleBlock + inlineToc);

// code blocks: numbered details with one span per line (numbers come from CSS)
var detail = 0;
body = body.replace(/<pre([^>]*)><code([^>]*)>([\s\S]*?)<\/code><\/pre>/g, function (all, preAttr, codeAttr, code) {
  detail++;
  var lines = code.replace(/\n$/, '').split('\n'),
      numbered = code.indexOf('<span') === -1;
  var content = numbered ? lines.map(function (line) {
    return '<span class="line">' + line + '</span>';
  }).join('\n') : code;
  return '<figure class="code-detail" data-lines="' + lines.length + '">' +
      '<figcaption><span class="label">Detail ' + detail + '</span>' +
      '<span class="code-detail__lines">' + lines.length + (lines.length === 1 ? ' line' : ' lines') + '</span></figcaption>' +
      '<pre' + preAttr + '><code' + codeAttr + (numbered ? ' class="numbered"' : '') + '>' + content + '</code></pre></figure>';
});

html = html.slice(0, bodyStart).replace('<main class="content content--text">',
    '<main id="top" class="content content--text content--post"><div class="post">') +
    body + '</div>' + marginToc + html.slice(mainClose);

fs.writeFileSync(file, html);
