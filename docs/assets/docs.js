/* Shared behaviour for the documentation pages (overview, parser, runtime, compile, import).
   The navigation itself is plain HTML in each page, so it works without JavaScript;
   this file only adds things on top of it:

   1. syntax highlighting (highlight.js)
   2. a copy button on every code block
   3. the mobile menu toggle
   4. "On this page": a list of the page's sections, built from its <h2>s,
      with the section you are reading highlighted as you scroll */

// 1. highlighting
if (window.hljs) hljs.highlightAll();

// 2. copy buttons. Visible on touch screens and on keyboard focus, not only on hover.
document.querySelectorAll(".docs-content pre").forEach((pre) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "copy-btn";
    button.textContent = "Copy";
    button.setAttribute("aria-label", "Copy this code");
    button.addEventListener("click", async () => {
        const code = pre.querySelector("code") || pre;
        try {
            await navigator.clipboard.writeText(code.textContent.trim());
            button.textContent = "Copied";
            button.classList.add("copied");
        } catch {
            button.textContent = "Select to copy";
        }
        setTimeout(() => { button.textContent = "Copy"; button.classList.remove("copied"); }, 1800);
    });
    pre.appendChild(button);
});

// 3. mobile menu: the button says whether the menu is open, Escape closes it
const toggle = document.getElementById("navToggle");
const menu = document.getElementById("mobileMenu");
if (toggle && menu) {
    const setOpen = (open) => {
        menu.classList.toggle("open", open);
        toggle.setAttribute("aria-expanded", String(open));
        toggle.textContent = open ? "Close" : "Menu";
    };
    toggle.addEventListener("click", () => setOpen(!menu.classList.contains("open")));
    menu.querySelectorAll("a").forEach((a) => a.addEventListener("click", () => setOpen(false)));
    document.addEventListener("keydown", (e) => { if (e.key === "Escape") setOpen(false); });
    document.addEventListener("click", (e) => {
        if (!menu.contains(e.target) && !toggle.contains(e.target)) setOpen(false);
    });
}

// 4. "On this page"
(() => {
    const sections = [...document.querySelectorAll(".docs-content section[id]")]
        .filter((s) => s.querySelector("h2"));
    if (sections.length < 2) return;

    const list = document.createElement("ol");
    for (const s of sections) {
        const li = document.createElement("li");
        const a = document.createElement("a");
        a.href = "#" + s.id;
        a.textContent = s.querySelector("h2").textContent;
        li.appendChild(a);
        list.appendChild(li);
    }

    // wide screens: a column on the right
    const aside = document.querySelector(".toc");
    if (aside) {
        const title = document.createElement("p");
        title.className = "toc-title";
        title.textContent = "On this page";
        aside.append(title, list);
    }

    // narrower screens: the same list, folded, at the top of the content
    const inline = document.createElement("details");
    inline.className = "toc-inline";
    const summary = document.createElement("summary");
    summary.textContent = "On this page";
    inline.appendChild(summary);
    inline.appendChild(list.cloneNode(true));
    inline.querySelectorAll("a").forEach((a) => a.addEventListener("click", () => (inline.open = false)));
    const first = document.querySelector(".docs-content > section");
    if (first) first.after(inline);

    // highlight the section being read: the last one whose heading passed the top of the screen
    const links = aside ? [...aside.querySelectorAll("a")] : [];
    const update = () => {
        const line = 120;
        let current = sections[0];
        for (const s of sections) if (s.getBoundingClientRect().top <= line) current = s;
        // at the very bottom, the last section counts as read even if it is short
        if (innerHeight + scrollY >= document.body.scrollHeight - 4) current = sections[sections.length - 1];
        for (const a of links) {
            const on = a.getAttribute("href") === "#" + current.id;
            a.classList.toggle("active", on);
            if (on) a.setAttribute("aria-current", "location"); else a.removeAttribute("aria-current");
        }
    };
    addEventListener("scroll", update, { passive: true });
    update();
})();
