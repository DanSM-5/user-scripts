#!/usr/bin/env node

// vim:fileencoding=utf-8:foldmethod=marker

//: PIXIV {{{ :---------------------------------------------------------------------

// NOTICE: version with 1 or 2 seconds is to avoid spamming too much pixiv's servers

// Pixiv - Add likes (non liked)
Array.from(
    /* Pixiv - Add likes (non liked) */
    document.querySelectorAll('.fYcrPo')
)
  .map((el, i) => setTimeout( () => el.parentElement.click(), i * 1000))

Array.from(
    /* Pixiv - Add likes (non liked) */
    document.querySelectorAll('.fYcrPo')
)
  .map((el, i) => setTimeout( () => el.parentElement.click(), i * 2 * 1000))

// Pixiv - Remove likes from items
Array.from(
    /* Pixiv - Remove likes from items */
    document.querySelectorAll('.bXjFLc')
)
  .map((el, i) => setTimeout( () => el.parentElement.click(), i * 1000))

Array.from(
     /* Pixiv - Remove likes from items */
    document.querySelectorAll('.bXjFLc')
)
  .map((el, i) => setTimeout( () => el.parentElement.click(), i * 2 * 1000))

// Pixiv - Get all url from unliked items
Array.from(
    /* Pixiv - Get all url from unliked items */
    document.querySelectorAll('li a.iUsZyY:has(+ div .fYcrPo)')
).reduce((links, a) => `${links}\n${a.href}`, '')

// Pixiv copy link search
Array.from(
   /* Pixiv copy link search */
   document.querySelectorAll('.khjDVZ')
)
  .reduce((acc, curr) => `${acc}\n${curr.href}`, '')

// Pixiv - Get all url from liked items
Array.from(
    /* Pixiv - Get all url from liked items */
    document.querySelectorAll('li a.iUsZyY:has(+ div .bXjFLc)')
).reduce((links, a) => `${links}\n${a.href}`, '')

// Pixiv - Get all links from contest
Array.from(
    /* Pixiv - Get all links from contest */
    document.querySelectorAll('.thumbnail-container a')
).reduce((links, a) => `${links}\n${a.href}`, '')

// Pixiv - Get all links from liked items contest
Array.from(
    /* Pixiv - Get all links from liked items contest */
    document.querySelectorAll('.thumbnail-container a:has(+ .bookmark-container span.on)')
).reduce((links, a) => `${links}\n${a.href}`, '')

// Pixiv - Get all links from unliked items contest
Array.from(
    /* Pixiv - Get all links from unliked items contest */
    document.querySelectorAll('.thumbnail-container a:has(+ .bookmark-container span:not(.on))')
).reduce((links, a) => `${links}\n${a.href}`, '')

// Pixiv - Unlike all from contest - NOT RECOMENDED PAGE RELOAD
Array.from(
    /* Pixiv - Unlike all from contest - NOT RECOMENDED PAGE RELOAD */
    document.querySelectorAll('.bookmark-container span:not(.on)')
).map((span, i) => setTimeout(() => span.click(), i * 2 * 1000))

// Pixiv - Like all unliked from contest
Array.from(
    /* Pixiv - Like all unliked from contest */
    document.querySelectorAll('.bookmark-container span:not(.on)')
).map((span, i) => setTimeout(() => span.click(), i * 2 * 1000))

//: }}} :---------------------------------------------------------------------------

//: FANBOX {{{ :--------------------------------------------------------------------

// Fanbox - like all
Array.from(
    /* Fanbox - like all */
    document.querySelectorAll('.cYueYD')
)
  .map((el, i) => setTimeout( () => el.click(), i * 1000))

// Fanbox - unlike all
Array.from(
    /* Fanbox - unlike all */
    document.querySelectorAll('.fxIlKe')
)
  .map((el, i) => setTimeout( () => el.click(), i * 1000))

//: }}} :---------------------------------------------------------------------------

//: KEMONO {{{ :--------------------------------------------------------------------

// Kemono - Select all urls in page
Array.from(
  /* Kemono - Select all urls in page */
  document.querySelectorAll('#main > section > div.card-list.card-list--legacy a')
)
  .reduce((links, curr) => `${links}\n${curr.href}`, '')

//: }}} :---------------------------------------------------------------------------

//: DANBOORU {{{ :------------------------------------------------------------------

// Danbooru - Select all urls in a page

Array.from(
    /* Danbooru - Select all urls in a page */
    document.querySelectorAll('a.post-preview-link'),
).reduce((links, a) => `${links}\n${a.href}`, '')

//: }}} :---------------------------------------------------------------------------

//: ARCA.LIVE {{{ :-----------------------------------------------------------------

// Arca.live - Get all links from post
Array.from(
    /* Arca.live - Get all links from post */
    document.querySelectorAll('.article-content a')
).reduce((linkString, link) => `${link.href}\n${linkString}`, '');

// Arca.live - Get emoticons
Array.from(
    /* Arca.live - Get emoticons */
    document.querySelectorAll('.emoticons-wrapper img')
).reduce((linkString, link) => `${link.src}\n${linkString}`, '');

// Arca.live - Get animated emoticons
Array.from(
    /* Arca.live - Get animated emoticons */
    document.querySelectorAll('video.emoticon')
).reduce((linkString, link) => `${link.src}\n${linkString}`, '');

//: }}} :---------------------------------------------------------------------------

