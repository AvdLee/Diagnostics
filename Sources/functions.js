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
        el.style.display = shouldShow ? 'block' : 'none';
    });
}

function showSystemLogsWithFilter(shouldShow, className, filterString) {
    let regex = null;
    if (filterString) {
        try {
            regex = new RegExp(filterString, 'i');
        } catch (e) {
            regex = null;
        }
    }
    document.querySelectorAll(className).forEach(function (el) {
        if (regex && !regex.test(el.textContent)) {
            el.style.display = 'none';
        } else if (filterString && !regex && !el.textContent.includes(filterString)) {
            el.style.display = 'none';
        } else if (shouldShow) {
            el.style.display = 'block';
        } else {
            el.style.display = 'none';
        }
    });
}

window.onload = (function () {
    document.getElementById("expand-sections").onclick = function() {
        expandElements(true);
    };
    document.getElementById("collapse-sections").onclick = function() {
        expandElements(false);
    };

    document.getElementById('system-logs').addEventListener('change', (event) => {
      if (event.currentTarget.checked) {
        showSystemLogs(true, '.system');
      } else {
        showSystemLogs(false, '.system');
      }
    });

    document.getElementById('debug-logs').addEventListener('change', (event) => {
      if (event.currentTarget.checked) {
        showSystemLogs(true, '.debug');
      } else {
        showSystemLogs(false, '.debug');
      }
    });

    document.getElementById('error-logs').addEventListener('change', (event) => {
      if (event.currentTarget.checked) {
        showSystemLogs(true, '.error');
      } else {
        showSystemLogs(false, '.error');
      }
    });

    document.getElementById('filter-btn').addEventListener('click', function () {
      var searchValue = document.getElementById('log-filter').value.trim();
      showSystemLogsWithFilter(document.getElementById('system-logs').checked, '.system', searchValue);
      showSystemLogsWithFilter(document.getElementById('debug-logs').checked, '.debug', searchValue);
      showSystemLogsWithFilter(document.getElementById('error-logs').checked, '.error', searchValue);
     });
});
