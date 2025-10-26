#!/usr/bin/env node

// vim:fileencoding=utf-8:foldmethod=marker

// @ts-check

//: PIXIV {{{ :---------------------------------------------------------------------

// Sample link and like buttons
// <ul class="sc-e83d358-1 gIHHFW"> 
//   <li size="1" offset="0" class="sc-e83d358-2 sc-e83d358-3 sc-64e0b1a1-1 ijXKlM jrXECC"> 
//     <div class="sc-38ec486e-5 gCNcAW">
//       <div class="sc-38ec486e-3 ckvtHT"> 
//         <div width="184" height="184" class="sc-b01c604f-0 dwXrvb">
//           <a class="sc-b01c604f-16 ednnFK sc-fqkvVR hdEsnq" data-gtm-value="126677909" data-gtm-user-id="101223078" href="/en/artworks/126677909">
//             <div class="sc-4822cddd-0 eCgTWT">
//               <div radius="4" class="sc-b01c604f-9 eTVpcd">
//               <img alt="Fate/Apocrypha / Poll form! (Link in description) / January 29th, 2025" class="sc-b01c604f-10 elxbqC" src="https://i.pximg.net/c/250x250_80_a2/img-master/img/2025/01/29/08/06/33/126677909_p0_square1200.jpg" style="object-fit: cover; object-position: center center;">
//             </div>
//             </div>
//               <div class="sc-b01c604f-12 kqssly">
//               <div class="sc-b01c604f-13 grTVtx">
//             </div>
//               <div class="sc-b01c604f-5 iZTwAm">
//                 <div class="sc-a686e337-0 cKmWeE">
//                   <span class="sc-a686e337-1 etbaSX">
//                     <span class="sc-64133715-0 jVVkFN">
//                     <svg viewBox="0 0 9 10" size="9" class="sc-64133715-1 etuVrj">
//                       <path d="M8,3 C8.55228475,3 9,3.44771525 9,4 L9,9 C9,9.55228475 8.55228475,10 8,10 L3,10 C2.44771525,10 2,9.55228475 2,9 L6,9 C7.1045695,9 8,8.1045695 8,7 L8,3 Z M1,1 L6,1 C6.55228475,1 7,1.44771525 7,2 L7,7 C7,7.55228475 6.55228475,8 6,8 L1,8 C0.44771525,8 0,7.55228475 0,7 L0,2 C0,1.44771525 0.44771525,1 1,1 Z" transform=""></path>
//                     </svg>
//                     </span>
//                   </span>
//                   <span>3</span>
//                 </div>
//               </div>
//             </div>
//           </a>
//         <div class="sc-38ec486e-4 flotNu">
//         <div class="">
//           <button type="button" class="sc-782b0553-0 hMoHjj">
//             <svg viewBox="0 0 32 32" width="32" height="32" class="sc-976c77a4-1 fWFQGs">
//               <path d="M21,5.5 C24.8659932,5.5 28,8.63400675 28,12.5 C28,18.2694439 24.2975093,23.1517313 17.2206059,27.1100183 C16.4622493,27.5342993 15.5379984,27.5343235 14.779626,27.110148 C7.70250208,23.1517462 4,18.2694529 4,12.5 C4,8.63400691 7.13400681,5.5 11,5.5 C12.829814,5.5 14.6210123,6.4144028 16,7.8282366 C17.3789877,6.4144028 19.170186,5.5 21,5.5 Z"></path>
//               <path d="M16,11.3317089 C15.0857201,9.28334665 13.0491506,7.5 11,7.5 C8.23857625,7.5 6,9.73857647 6,12.5 C6,17.4386065 9.2519779,21.7268174 15.7559337,25.3646328 C15.9076021,25.4494645 16.092439,25.4494644 16.2441073,25.3646326 C22.7480325,21.7268037 26,17.4385986 26,12.5 C26,9.73857625 23.7614237,7.5 21,7.5 C18.9508494,7.5 16.9142799,9.28334665 16,11.3317089 Z" class="sc-976c77a4-0 dZTXdH"></path>
//             </svg>
//           </button>
//         </div>
//         </div>
//       </div>
//     </div>
//     <div class="sc-38ec486e-1 fLOa-DD">
//     <a class="sc-38ec486e-6 jRtZSE" href="/en/artworks/126677909">Poll form! (Link in description)
//     </a>
//     </div>
//     </div>
//     </li>
//     <li size="1" offset="0" class="sc-e83d358-2 sc-e83d358-3 sc-64e0b1a1-1 ijXKlM jrXECC">
//     <div class="sc-38ec486e-5 gCNcAW">
//     <div class="sc-38ec486e-3 ckvtHT">
//     <div width="184" height="184" class="sc-b01c604f-0 dwXrvb">
//     <a class="sc-b01c604f-16 ednnFK sc-fqkvVR hdEsnq" data-gtm-value="126676061" data-gtm-user-id="101223078" href="/en/artworks/126676061">
//     <div class="sc-4822cddd-0 eCgTWT">
//     <div radius="4" class="sc-b01c604f-9 eTVpcd">
//     <img alt="Size Contest (crossover) / January 29th, 2025" class="sc-b01c604f-10 elxbqC" src="https://i.pximg.net/c/250x250_80_a2/img-master/img/2025/01/29/05/48/57/126676061_p0_square1200.jpg" style="object-fit: cover; object-position: center center;">
//     </div>
//     </div>
//     <div class="sc-b01c604f-12 kqssly">
//     <div class="sc-b01c604f-13 grTVtx">
//     </div>
//     <div class="sc-b01c604f-5 iZTwAm">
//     <div class="sc-a686e337-0 cKmWeE">
//     <span class="sc-a686e337-1 etbaSX">
//     <span class="sc-64133715-0 jVVkFN">
//     <svg viewBox="0 0 9 10" size="9" class="sc-64133715-1 etuVrj">
//     <path d="M8,3 C8.55228475,3 9,3.44771525 9,4 L9,9 C9,9.55228475 8.55228475,10 8,10 L3,10
//       C2.44771525,10 2,9.55228475 2,9 L6,9 C7.1045695,9 8,8.1045695 8,7 L8,3 Z M1,1 L6,1
//       C6.55228475,1 7,1.44771525 7,2 L7,7 C7,7.55228475 6.55228475,8 6,8 L1,8 C0.44771525,8
//       0,7.55228475 0,7 L0,2 C0,1.44771525 0.44771525,1 1,1 Z" transform="">
//     </path>
//     </svg>
//     </span>
//     </span>
//     <span>3
//     </span>
//     </div>
//     </div>
//     </div>
//     </a>
//     <div class="sc-38ec486e-4 flotNu">
//     <div class="">
//     <button type="button" class="sc-782b0553-0 hMoHjj">
//     <svg viewBox="0 0 32 32" width="32" height="32" class="sc-976c77a4-1 bVNeCg">
//     <path d="
//         M21,5.5 C24.8659932,5.5 28,8.63400675 28,12.5 C28,18.2694439 24.2975093,23.1517313 17.2206059,27.1100183
//         C16.4622493,27.5342993 15.5379984,27.5343235 14.779626,27.110148 C7.70250208,23.1517462 4,18.2694529 4,12.5
//         C4,8.63400691 7.13400681,5.5 11,5.5 C12.829814,5.5 14.6210123,6.4144028 16,7.8282366
//         C17.3789877,6.4144028 19.170186,5.5 21,5.5 Z">
//     </path>
//     <path d="M16,11.3317089 C15.0857201,9.28334665 13.0491506,7.5 11,7.5
//           C8.23857625,7.5 6,9.73857647 6,12.5 C6,17.4386065 9.2519779,21.7268174 15.7559337,25.3646328
//           C15.9076021,25.4494645 16.092439,25.4494644 16.2441073,25.3646326 C22.7480325,21.7268037 26,17.4385986 26,12.5
//           C26,9.73857625 23.7614237,7.5 21,7.5 C18.9508494,7.5 16.9142799,9.28334665 16,11.3317089 Z" class="sc-976c77a4-0 dZTXdH">
//     </path>
//     </svg>
//     </button>
//     </div>
//     </div>
//     </div>
//     </div>
//     <div class="sc-38ec486e-1 fLOa-DD">
//     <a class="sc-38ec486e-6 jRtZSE" href="/en/artworks/126676061">Size Contest (crossover)
//     </a>
//     </div>
//     </div>
//   </li>
// </ul>


// NOTICE: version with 1 or 2 seconds is to avoid spamming too much pixiv's servers

// Pixiv - Add likes (non liked)
Array.from(
    /* Pixiv - Add likes (non liked) */
    document.querySelectorAll('.fWFQGs')
)
  .map(el => el.parentElement)
  .map((el, i) => setTimeout( () => el?.click(), i * 1000))

Array.from(
    /* Pixiv - Add likes (non liked) */
    document.querySelectorAll('.fWFQGs')
)
  .map(el => el.parentElement)
  .map((el, i) => setTimeout( () => el?.click(), i * 2 * 1000))

// Pixiv - Remove likes from items
Array.from(
    /* Pixiv - Remove likes from items */
    document.querySelectorAll('.bVNeCg')
)
  .map(el => el.parentElement)
  .map((el, i) => setTimeout( () => el?.click(), i * 1000))

Array.from(
     /* Pixiv - Remove likes from items */
    document.querySelectorAll('.bVNeCg')
)
  .map(el => el.parentElement)
  .map((el, i) => setTimeout( () => el?.click(), i * 2 * 1000))

// Pixiv - Get all urls in page
Array.from(
    /* Pixiv - Get all urls in apge */
    document.querySelectorAll('li a.ednnFK')
// @ts-ignore
).reduce((links, /** @type {HTMLAnchorElement} */ a) => `${links}\n${a.href}`, '')

// Pixiv - Get all url from unliked items
Array.from(
    /* Pixiv - Get all url from unliked items */
    document.querySelectorAll('li a.ednnFK:has(+ div .fWFQGs)')
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
    document.querySelectorAll('li a.ednnFK:has(+ div .bVNeCg)')
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
    document.querySelectorAll('.fWFQGs')
  )
  // @ts-ignore
  .map((/** @type {HTMLElement} */ el) => el.parentElement),
  getNextPage: () => (/** @type {HTMLElement} */ (document.querySelectorAll('.sc-facdf6d-0.cujffJ button:not(.dcmkry) + .sc-facdf6d-2.hGMPlP:not(.giMfei)')?.[0]))
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

