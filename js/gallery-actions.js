#!/usr/bin/env node

// vim:fileencoding=utf-8:foldmethod=marker

// @ts-check

//: PIXIV {{{ :---------------------------------------------------------------------

// NOTICE: version with 1 or 2 seconds is to avoid spamming too much pixiv's servers

// Pixiv - Add likes (non liked)
Array.from(
    /* Pixiv - Add likes (non liked) */
    document.querySelectorAll('.gAARvC')
)
  .map(el => el.parentElement)
  .map((el, i) => setTimeout( () => el?.click(), i * 1000))

Array.from(
    /* Pixiv - Add likes (non liked) */
    document.querySelectorAll('.gAARvC')
)
  .map(el => el.parentElement)
  .map((el, i) => setTimeout( () => el?.click(), i * 2 * 1000))

// Pixiv - Remove likes from items
Array.from(
    /* Pixiv - Remove likes from items */
    document.querySelectorAll('.wQCIS')
)
  .map(el => el.parentElement)
  .map((el, i) => setTimeout( () => el?.click(), i * 1000))

Array.from(
     /* Pixiv - Remove likes from items */
    document.querySelectorAll('.wQCIS')
)
  .map(el => el.parentElement)
  .map((el, i) => setTimeout( () => el?.click(), i * 2 * 1000))

// Pixiv - Get all urls in page
Array.from(
    /* Pixiv - Get all urls in apge */
    document.querySelectorAll('li a.kGsreV')
// @ts-ignore
).reduce((links, /** @type {HTMLAnchorElement} */ a) => `${links}\n${a.href}`, '')

// Pixiv - Get all url from unliked items
Array.from(
    /* Pixiv - Get all url from unliked items */
    document.querySelectorAll('li a.kGsreV:has(+ div .gAARvC)')
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
    document.querySelectorAll('li a.kGsreV:has(+ div .wQCIS)')
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
 * @typedef {{ getElements: () => HTMLElement[]; getNextPage: () => HTMLElement | null | undefined; signal?: { aborted: boolean }; delay?: number }} PaginatedClickProps
 */

/**
 * Function to apply likes per page in pixiv
 *
 * @param {PaginatedClickProps} props  Props for paginated click process
 * @returns {Promise<void>}
 */
const paginatedClickProcess = ({
  getElements = () => [],
  getNextPage = () => null,
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

  const moveNextPage = (/** @type {{ (): Promise<any[]>; (): Promise<any>; }} */ callPageProcess) => {
    return callPageProcess().then(() => {
      /**
       * @type {HTMLButtonElement}
       */
      // @ts-ignore
      const nextPageBtn = getNextPage()
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

// Pixiv - Paginated process
paginatedClickProcess({
  // @ts-ignore
  getElements: () => Array.from(
    /* Pixiv - Add likes (non liked) */
    document.querySelectorAll('.gAARvC')
  )
  // @ts-ignore
  .map((/** @type {HTMLElement} */ el) => el.parentElement),
  getNextPage: () => (/** @type {HTMLElement} */ (document.querySelectorAll('.sc-ddbdb82a-1.jPzasX:not(.gMZEpK) + a:not([hidden])')?.[0]))
});


//: }}} :---------------------------------------------------------------------------

//: FANBOX {{{ :--------------------------------------------------------------------

// Fanbox - like all
Array.from(
    /* Fanbox - like all */
    document.querySelectorAll('.fQaTqZ')
)
  // @ts-ignore
  .map((el, i) => setTimeout( () => el.click(), i * 1000))

// Fanbox - unlike all
Array.from(
    /* Fanbox - unlike all */
    document.querySelectorAll('.fRvFGs')
)
  // @ts-ignore
  .map((el, i) => setTimeout( () => el.click(), i * 1000))


// Fanbox - paginated like
paginatedClickProcess({
  // @ts-ignore
  getElements: () => Array.from(
    /* Fanbox - like all */
    document.querySelectorAll('.fQaTqZ')
  ),
  getNextPage: () => (/** @type {HTMLElement} */ (document.querySelector('.Pagination__SelectedItemWrapper-sc-1oq4naf-3 + a'))),
});

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

