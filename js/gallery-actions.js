#!/usr/bin/env node

// vim:fileencoding=utf-8:foldmethod=marker

// @ts-check

//: PIXIV {{{ :---------------------------------------------------------------------

// Sample link and like buttons
// <div width="184" height="184" class="sc-a57c16e6-0 fLGndj">
//   <a class="sc-a57c16e6-16 dGiDgy sc-fqkvVR fJFKsi" data-gtm-value="129807266" data-gtm-user-id="3576344" href="/en/artworks/129807266">
//     <div class="sc-e85d81bc-0 eLoxRg">
//       <div radius="4" class="sc-a57c16e6-9 fDDgQt">
//         <img src="https://i.pximg.net/c/250x250_80_a2/custom-thumb/img/2025/04/28/22/18/59/129807266_p0_custom1200.jpg" alt="EpicSeven, epic7, yufine(epic7) / Exclusive: Abyssal Yufine" class="sc-a57c16e6-10 iaqWlq" style="object-fit: cover; object-position: center center;">
//       </div>
//     </div>
//     <div class="sc-a57c16e6-12 kMflgS">
//       <div class="sc-a57c16e6-13 hLJzFN">
//         <div class="sc-a57c16e6-15 gCATCR">
//           <div class="sc-297744c7-0 fPWvQd">R-18</div>
//         </div>
//       </div>
//       <div class="sc-a57c16e6-5 OiTjW">
//         <div class="sc-b5e6ab10-0 hfQbJx">
//           <span class="sc-b5e6ab10-1 dEqZum">
//             <span class="sc-c13d4f40-0 dXSgZe">
//               <svg viewBox="0 0 9 10" size="9" class="sc-c13d4f40-1 bKxYLA">
//                 <path d="M8,3 C8.55228475,3 9,3.44771525 9,4 L9,9 C9,9.55228475 8.55228475,10 8,10 L3,10C2.44771525,10 2,9.55228475 2,9 L6,9 C7.1045695,9 8,8.1045695 8,7 L8,3 Z M1,1 L6,1C6.55228475,1 7,1.44771525 7,2 L7,7 C7,7.55228475 6.55228475,8 6,8 L1,8 C0.44771525,80,7.55228475 0,7 L0,2 C0,1.44771525 0.44771525,1 1,1 Z" transform=""></path>
//               </svg>
//             </span>
//           </span>
//           <span>11</span>
//         </div>
//       </div>
//     </div>
//   </a>
//   <div class="sc-5a760b36-4 btqmcy">
//     <div class="">
//       <button type="button" class="sc-e48c39c9-0 ialGvh">
//         <svg viewBox="0 0 32 32" width="32" height="32" class="sc-4258e52e-1 lbkCkj">
//           <path d="M21,5.5 C24.8659932,5.5 28,8.63400675 28,12.5 C28,18.2694439 24.2975093,23.1517313 17.2206059,27.1100183C16.4622493,27.5342993 15.5379984,27.5343235 14.779626,27.110148 C7.70250208,23.1517462 4,18.2694529 4,12.5C4,8.63400691 7.13400681,5.5 11,5.5 C12.829814,5.5 14.6210123,6.4144028 16,7.8282366C17.3789877,6.4144028 19.170186,5.5 21,5.5 Z"></path>
//           <path d="M16,11.3317089 C15.0857201,9.28334665 13.0491506,7.5 11,7.5C8.23857625,7.5 6,9.73857647 6,12.5 C6,17.4386065 9.2519779,21.7268174 15.7559337,25.3646328C15.9076021,25.4494645 16.092439,25.4494644 16.2441073,25.3646326 C22.7480325,21.7268037 26,17.4385986 26,12.5C26,9.73857625 23.7614237,7.5 21,7.5 C18.9508494,7.5 16.9142799,9.28334665 16,11.3317089 Z" class="sc-4258e52e-0 ktvYyV"></path>
//         </svg>
//       </button>
//     </div>
//   </div>
// </div>


// NOTICE: version with 1 or 2 seconds is to avoid spamming too much pixiv's servers

// Pixiv - Add likes (non liked)
Array.from(
    /* Pixiv - Add likes (non liked) */
    document.querySelectorAll('.hapWHH')
)
  .map(el => el.parentElement)
  .map((el, i) => setTimeout( () => el?.click(), i * 1000))

Array.from(
    /* Pixiv - Add likes (non liked) */
    document.querySelectorAll('.hapWHH')
)
  .map(el => el.parentElement)
  .map((el, i) => setTimeout( () => el?.click(), i * 2 * 1000))

// Pixiv - Remove likes from items
Array.from(
    /* Pixiv - Remove likes from items */
    document.querySelectorAll('.lbkCkj')
)
  .map(el => el.parentElement)
  .map((el, i) => setTimeout( () => el?.click(), i * 1000))

Array.from(
     /* Pixiv - Remove likes from items */
    document.querySelectorAll('.lbkCkj')
)
  .map(el => el.parentElement)
  .map((el, i) => setTimeout( () => el?.click(), i * 2 * 1000))

// Pixiv - Get all urls in page
Array.from(
    /* Pixiv - Get all urls in apge */
    document.querySelectorAll('li a.XiaPU')
// @ts-ignore
).reduce((links, /** @type {HTMLAnchorElement} */ a) => `${links}\n${a.href}`, '')

// Pixiv - Get all url from unliked items
Array.from(
    /* Pixiv - Get all url from unliked items */
    document.querySelectorAll('li a.XiaPU:has(+ div .hapWHH)')
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
    document.querySelectorAll('li a.XiaPU:has(+ div .lbkCkj)')
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
 * @typedef {{
 *   getElements: () => HTMLElement[];
 *   getNextPage: () => HTMLElement | null | undefined;
 *   signal?: { aborted: boolean; reason?: string; };
 *   delay?: number; nextPageStartDelay?: number;
 *   skipErrors?: boolean;
 * }} PaginatedClickProps
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
  signal = { aborted: false, reason: '[Unknown]' },
  delay = 2000,
  nextPageStartDelay = 3000,
  skipErrors = true,
}) => {
  /**
   * @type {{ promise: Promise<void>; reject: typeof Promise.reject<void>; resolve: typeof Promise.resolve<void> }}
   */
  // @ts-ignore
  const pending = Promise.withResolvers()

  /**
   * Clinks element and resolves after the specified delay
   * @param {{ click: () => void; }} element Object with a click function
   * @returns {Promise<void>} Resolved promise when the required delay time has been elapsed
   */
  const clickElement = (element) => {
    return new Promise((/** @type {(value?: never) => void} */resolve, reject) => {
      setTimeout(() => {
        if (signal.aborted) {
          // @ts-expect-error Using cause argument in error constructor
          pending.reject(new Error('Process aborted', { cause: signal.reason }));
          reject();
          return;
        }

        element.click();
        resolve();
      }, delay);
    });
  };

  // Definition change to ensure next like depends on previous
  // and not just the pre-calculated time for the given element
  // It should also be more memory efficient as it avoids creating
  // a lot of promises at once.
  // const onAllElements = () => Promise.all(
  //   getElements()
  //     .map(clickElement),
  // );

  const onAllElements = async () => {
    const elements = getElements();
    const length = elements.length;

    for (let i = 0; i < length; i++) {
      const element = elements[i];

      try {
        await clickElement(element);
      } catch (error) {
        console.error(`Item ${i} caused an error:`, element, error);
        // If not skipping errors, throw to stop here.
        if (skipErrors === false) {
          // @ts-expect-error Using cause argument in error constructor
          throw new Error(`Error clicking item ${i}`, { cause: error })
        }
      }

    }
  };

  const processPage = (/** @type {{ (): Promise<any>; (): Promise<any>; }} */ callPageProcess) => {
    return callPageProcess().then(() => {
      /**
       * @type {HTMLButtonElement | null | undefined}
       */
      // @ts-expect-error Use HTMLElement as a HTMLButtonElement
      const nextPageBtn = getNextPage()
      if (!nextPageBtn) {
        pending.resolve();
        return;
      }

      setTimeout(() => {
        // Go to next page
        nextPageBtn.click();

        // Wait `nextPageStartDelay` ms before starting again
        setTimeout(() => {
          processPage(callPageProcess);
        }, nextPageStartDelay);
        // We consider clicking the next page button needs the same delay
        // as clicking on an item itself.
      }, delay);
    })
    .catch(e => {
      console.warn('Ended cycle unexpectedly');
      // @ts-ignore
      pending.reject(new Error('Cannot continue paginated process:' , { cause: e }))
    });
  };

  processPage(onAllElements);
  return pending.promise
};

// Pixiv - Paginated process
paginatedClickProcess({
  // @ts-ignore
  getElements: () => Array.from(
    /* Pixiv - Add likes (non liked) */
    document.querySelectorAll('.hapWHH')
  )
  // @ts-ignore
  .map((/** @type {HTMLElement} */ el) => el.parentElement),
  getNextPage: () => (/** @type {HTMLElement} */ (document.querySelectorAll('.sc-27a0ff07-0.bbkQMy button:not(.dcmkry) + .sc-27a0ff07-2.jGoxAA:not(.iXwGwx)')?.[0]))
}).then(() => console.log('End'));


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

