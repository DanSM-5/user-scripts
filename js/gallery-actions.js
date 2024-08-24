#!/usr/bin/env node

// vim:fileencoding=utf-8:foldmethod=marker

// @ts-check

//: PIXIV {{{ :---------------------------------------------------------------------

// NOTICE: version with 1 or 2 seconds is to avoid spamming too much pixiv's servers

// Pixiv - Add likes (non liked)
Array.from(
    /* Pixiv - Add likes (non liked) */
    document.querySelectorAll('.fYcrPo')
)
  .map(el => el.parentElement)
  .map((el, i) => setTimeout( () => el?.click(), i * 1000))

Array.from(
    /* Pixiv - Add likes (non liked) */
    document.querySelectorAll('.fYcrPo')
)
  .map(el => el.parentElement)
  .map((el, i) => setTimeout( () => el?.click(), i * 2 * 1000))

// Pixiv - Remove likes from items
Array.from(
    /* Pixiv - Remove likes from items */
    document.querySelectorAll('.bXjFLc')
)
  .map(el => el.parentElement)
  .map((el, i) => setTimeout( () => el?.click(), i * 1000))

Array.from(
     /* Pixiv - Remove likes from items */
    document.querySelectorAll('.bXjFLc')
)
  .map(el => el.parentElement)
  .map((el, i) => setTimeout( () => el?.click(), i * 2 * 1000))

// Pixiv - Get all url from unliked items
Array.from(
    /* Pixiv - Get all url from unliked items */
    document.querySelectorAll('li a.iUsZyY:has(+ div .fYcrPo)')
// @ts-ignore
).reduce((links, /** @type {HTMLAnchorElement} */ a) => `${links}\n${a.href}`, '')

// Pixiv copy link search
Array.from(
   /* Pixiv copy link search */
   document.querySelectorAll('.khjDVZ')
)
  // @ts-ignore
  .reduce((acc, /** @type {HTMLAnchorElement} */ curr) => `${acc}\n${curr.href}`, '')

// Pixiv - Get all url from liked items
Array.from(
    /* Pixiv - Get all url from liked items */
    document.querySelectorAll('li a.iUsZyY:has(+ div .bXjFLc)')
// @ts-ignore
).reduce((links, a) => `${links}\n${a.href}`, '')

// Pixiv - Get all links from contest
Array.from(
    /* Pixiv - Get all links from contest */
    document.querySelectorAll('.thumbnail-container a')
// @ts-ignore
).reduce((links, a) => `${links}\n${a.href}`, '')

// Pixiv - Get all links from liked items contest
Array.from(
    /* Pixiv - Get all links from liked items contest */
    document.querySelectorAll('.thumbnail-container a:has(+ .bookmark-container span.on)')
// @ts-ignore
).reduce((links, a) => `${links}\n${a.href}`, '')

// Pixiv - Get all links from unliked items contest
Array.from(
    /* Pixiv - Get all links from unliked items contest */
    document.querySelectorAll('.thumbnail-container a:has(+ .bookmark-container span:not(.on))')
// @ts-ignore
).reduce((links, a) => `${links}\n${a.href}`, '')

// Pixiv - Unlike all from contest - NOT RECOMENDED PAGE RELOAD
Array.from(
    /* Pixiv - Unlike all from contest - NOT RECOMENDED PAGE RELOAD */
    document.querySelectorAll('.bookmark-container span:not(.on)')
)
  // @ts-ignore
  .map((span, i) => setTimeout(() => span.click(), i * 2 * 1000))

// Pixiv - Like all unliked from contest
Array.from(
    /* Pixiv - Like all unliked from contest */
    document.querySelectorAll('.bookmark-container span:not(.on)')
)
  // @ts-ignore
  .map((span, i) => setTimeout(() => span.click(), i * 2 * 1000))

/**
 * @typedef {{ getElements: () => HTMLElement[]; signal: { aborted: boolean }; delay: number }} PaginatedClickProps
 */

/**
 * Function to apply likes per page in pixiv
 *
 * @param {PaginatedClickProps} props  Props for paginated click process
 * @returns {Promise<void>}
 */
const paginatedClickProcess = ({
  getElements = () => [],
  signal = { aborted: false },
  delay = 2000,
}) => {
  /**
   * @type {{ promise: Promise<void>; reject: typeof Promise.reject<void>; resolve: typeof Promise.resolve<void> }}
   */
  // @ts-ignore
  const pending = Promise.withResolvers()
  const clickElement = (/** @type {{ click: () => void; }} */ element, /** @type {number} */ index) => {
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        if (signal.aborted) {
          // @ts-ignore
          pending.reject(new Error('Process aborted', { cause: signal.reason }));
          reject();
          return;
        }

        element.click();
        // @ts-ignore
        resolve();
      }, index * delay);
    });
  };

  const onAllElements = () => Promise.all(
    getElements()
      .map(clickElement),
  );

  const moveNextPage = (callPageProcess) => {
    return callPageProcess().then(() => {
      /**
       * @type {HTMLButtonElement}
       */
      // @ts-ignore
      const nextPageBtn = document.querySelectorAll('.sc-xhhh7v-1.hqFKax:not(.iiDpnk) + a:not([hidden])')?.[0];
      if (!nextPageBtn) {
        pending.resolve();
        return;
      }
      setTimeout(() => {
        nextPageBtn.click();
        setTimeout(() => {
          moveNextPage(callPageProcess);
        }, delay);
      }, delay);
    })
    .catch(e => {
      console.warn('Ended cycle');
      // @ts-ignore
      pending.reject(new Error('Cannot continue paginated process:' , { cause: e }))
    });
  };

  moveNextPage(onAllElements);
  return pending.promise
};

paginatedClickProcess({
  // @ts-ignore
  getElements: () => Array.from(
    /* Pixiv - Add likes (non liked) */
    document.querySelectorAll('.fYcrPo')
  )
  // @ts-ignore
  .map((/** @type {HTMLElement} */ el) => el.parentElement),
});

// const onAllElements = () => Promise.all(
//   Array.from(
//     /* Pixiv - Add likes (non liked) */
//     document.querySelectorAll('.fYcrPo')
//   )
//   .map(el => e.parentElement)
//   .map(
//     (el, i) => new Promise((resolve) => setTimeout(() => {
//       el.click();
//       resolve();
//     }, i * 2 * 1000))
//   ),
// );


//: }}} :---------------------------------------------------------------------------

//: FANBOX {{{ :--------------------------------------------------------------------

// Fanbox - like all
Array.from(
    /* Fanbox - like all */
    document.querySelectorAll('.cYueYD')
)
  // @ts-ignore
  .map((el, i) => setTimeout( () => el.click(), i * 1000))

// Fanbox - unlike all
Array.from(
    /* Fanbox - unlike all */
    document.querySelectorAll('.fxIlKe')
)
  // @ts-ignore
  .map((el, i) => setTimeout( () => el.click(), i * 1000))

//: }}} :---------------------------------------------------------------------------

//: KEMONO {{{ :--------------------------------------------------------------------

// Kemono - Select all urls in page
Array.from(
  /* Kemono - Select all urls in page */
  document.querySelectorAll('#main > section > div.card-list.card-list--legacy a')
)
  // @ts-ignore
  .reduce((links, curr) => `${links}\n${curr.href}`, '')

//: }}} :---------------------------------------------------------------------------

//: DANBOORU {{{ :------------------------------------------------------------------

// Danbooru - Select all urls in a page

Array.from(
    /* Danbooru - Select all urls in a page */
    document.querySelectorAll('a.post-preview-link'),
// @ts-ignore
).reduce((links, a) => `${links}\n${a.href}`, '')

//: }}} :---------------------------------------------------------------------------

//: ARCA.LIVE {{{ :-----------------------------------------------------------------

// Arca.live - Get all links from post
Array.from(
    /* Arca.live - Get all links from post */
    document.querySelectorAll('.article-content a')
// @ts-ignore
).reduce((linkString, link) => `${link.href}\n${linkString}`, '');

// Arca.live - Get emoticons
Array.from(
    /* Arca.live - Get emoticons */
    document.querySelectorAll('.emoticons-wrapper img')
// @ts-ignore
).reduce((linkString, link) => `${link.src}\n${linkString}`, '');

// Arca.live - Get animated emoticons
Array.from(
    /* Arca.live - Get animated emoticons */
    document.querySelectorAll('video.emoticon')
// @ts-ignore
).reduce((linkString, link) => `${link.src}\n${linkString}`, '');

//: }}} :---------------------------------------------------------------------------

