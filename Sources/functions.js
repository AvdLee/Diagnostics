const expandElements = shouldExpand => {
    let detailsElements = document.querySelectorAll("details");
    
    detailsElements = [...detailsElements];

    if (shouldExpand) {
        console.log("Expanding!");
        detailsElements.map(item => item.setAttribute("open", shouldExpand));
    } else {
        console.log("Collapsing!");
        detailsElements.map(item => item.removeAttribute("open"));
    }
};

function showSystemLogs(shouldShow, className) {
    document.querySelectorAll(className).forEach(function(el) {
        if (shouldShow) {
            el.style.display = 'block';
        } else {
            el.style.display = 'none';
        }
    });
}

function appendTextElement(parent, tagName, text, className) {
    const element = document.createElement(tagName);
    element.textContent = text;
    if (className) {
        element.className = className;
    }
    parent.appendChild(element);
    return element;
}

function renderLogEvent(event) {
    if (event.legacyHTML) {
        const template = document.createElement('template');
        template.innerHTML = event.legacyHTML;
        return template.content;
    }

    const paragraph = document.createElement('p');
    paragraph.className = event.level || 'debug';

    const parts = [];
    if (event.date) {
        parts.push(['log-date', event.date]);
    }
    if (event.prefix) {
        parts.push(['log-prefix', event.prefix]);
    }
    parts.push(['log-message', event.message || '']);

    parts.forEach(([className, text], index) => {
        if (index > 0) {
            appendTextElement(paragraph, 'span', ' | ', 'log-separator');
        }
        appendTextElement(paragraph, 'span', text, className);
    });

    return paragraph;
}

function renderLogSession(session) {
    const wrapper = document.createElement('div');
    wrapper.className = 'collapsible-session';
    const details = document.createElement('details');
    wrapper.appendChild(details);

    if (session.legacyHTML) {
        if (session.legacyHTML.includes('class="session-header')) {
            const template = document.createElement('template');
            template.innerHTML = session.legacyHTML;
            details.appendChild(template.content);
        } else {
            appendTextElement(details, 'summary', session.title || 'Unknown session title');
            const pre = document.createElement('pre');
            pre.textContent = session.legacyHTML;
            details.appendChild(pre);
        }
        return wrapper;
    }

    const summary = document.createElement('summary');
    const header = document.createElement('div');
    header.className = 'session-header';
    Object.keys(session.metadata || {}).sort().forEach(key => {
        const paragraph = document.createElement('p');
        appendTextElement(paragraph, 'span', `${key}: `);
        paragraph.appendChild(document.createTextNode(session.metadata[key]));
        header.appendChild(paragraph);
    });
    summary.appendChild(header);
    details.appendChild(summary);

    (session.events || []).forEach(event => {
        details.appendChild(renderLogEvent(event));
    });

    return wrapper;
}

function renderChapterContent(chapter) {
    const content = document.createElement('div');
    content.className = 'chapter-content';
    const data = chapter.data || {};

    if (data.type === 'table') {
        const table = document.createElement('table');
        (data.rows || []).forEach(row => {
            const tr = document.createElement('tr');
            appendTextElement(tr, 'th', row.key);
            appendTextElement(tr, 'td', row.value);
            table.appendChild(tr);
        });
        content.appendChild(table);
    } else if (data.type === 'logs') {
        const logSessions = document.createElement('div');
        logSessions.id = 'log-sessions';
        (data.sessions || []).slice().reverse().forEach(session => {
            logSessions.appendChild(renderLogSession(session));
        });
        content.appendChild(logSessions);
    } else if (data.type === 'preformatted') {
        const pre = document.createElement('pre');
        pre.textContent = data.value || '';
        content.appendChild(pre);
    } else if (data.type === 'legacyHTML') {
        content.innerHTML = data.value || chapter.legacyHTML || '';
    } else {
        content.textContent = data.value || '';
    }

    return content;
}

function renderDiagnosticsReport() {
    const dataElement = document.getElementById('diagnostics-report-data');
    const mountElement = document.getElementById('diagnostics-report');
    if (!dataElement || !mountElement) {
        return;
    }

    let report;
    try {
        report = JSON.parse(dataElement.textContent);
    } catch (error) {
        mountElement.textContent = `Unable to parse diagnostics report data: ${error}`;
        return;
    }

    const aside = document.createElement('aside');
    aside.className = 'nav-container';
    const nav = document.createElement('nav');
    const navList = document.createElement('ul');
    (report.chapters || []).forEach(chapter => {
        const listItem = document.createElement('li');
        const anchor = document.createElement('a');
        anchor.href = `#${chapter.id}`;
        anchor.textContent = chapter.title;
        listItem.appendChild(anchor);
        navList.appendChild(listItem);
    });

    [
        ['expand-sections', 'Expand sessions'],
        ['collapse-sections', 'Collapse sessions']
    ].forEach(([id, label]) => {
        const listItem = document.createElement('li');
        const button = appendTextElement(listItem, 'button', label);
        button.id = id;
        navList.appendChild(listItem);
    });

    [
        ['system-logs', 'Show system logs'],
        ['error-logs', 'Show error logs'],
        ['debug-logs', 'Show debug logs']
    ].forEach(([id, label]) => {
        const listItem = document.createElement('li');
        const input = document.createElement('input');
        input.type = 'checkbox';
        input.id = id;
        input.name = id;
        input.checked = true;
        const labelElement = appendTextElement(listItem, 'label', label);
        labelElement.htmlFor = id;
        listItem.prepend(input);
        navList.appendChild(listItem);
    });

    nav.appendChild(navList);
    aside.appendChild(nav);
    mountElement.appendChild(aside);

    const mainContent = document.createElement('div');
    mainContent.className = 'main-content';
    const header = document.createElement('header');
    appendTextElement(header, 'h1', report.title || 'Diagnostics Report');
    mainContent.appendChild(header);

    (report.chapters || []).forEach(chapter => {
        const chapterElement = document.createElement('div');
        chapterElement.className = 'chapter';
        const anchor = document.createElement('span');
        anchor.className = 'anchor';
        anchor.id = chapter.id;
        chapterElement.appendChild(anchor);
        appendTextElement(chapterElement, 'h3', chapter.title);
        chapterElement.appendChild(renderChapterContent(chapter));
        mainContent.appendChild(chapterElement);
    });

    mountElement.appendChild(mainContent);
}

window.onload = (function () {
    renderDiagnosticsReport();

    const expandSections = document.getElementById("expand-sections");
    if (expandSections) {
        expandSections.onclick = function() {
            expandElements(true);
        };
    }
    const collapseSections = document.getElementById("collapse-sections");
    if (collapseSections) {
        collapseSections.onclick = function() {
            expandElements(false);
        };
    }

    const systemLogs = document.getElementById('system-logs');
    if (systemLogs) {
        systemLogs.addEventListener('change', (event) => {
          if (event.currentTarget.checked) {
            showSystemLogs(true, '.system');
          } else {
            showSystemLogs(false, '.system');
          }
        });
    }

    const debugLogs = document.getElementById('debug-logs');
    if (debugLogs) {
        debugLogs.addEventListener('change', (event) => {
          if (event.currentTarget.checked) {
            showSystemLogs(true, '.debug');
          } else {
            showSystemLogs(false, '.debug');
          }
        });
    }

    const errorLogs = document.getElementById('error-logs');
    if (errorLogs) {
        errorLogs.addEventListener('change', (event) => {
          if (event.currentTarget.checked) {
            showSystemLogs(true, '.error');
          } else {
            showSystemLogs(false, '.error');
          }
        });
    }
});