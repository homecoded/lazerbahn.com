// blog posts and blog index: code details and the type filter
document.addEventListener('DOMContentLoaded', function () {
  var COLLAPSE_AFTER = 30;

  // copy button and collapsing for long code details
  var details = document.querySelectorAll('.code-detail');
  for (var i = 0; i < details.length; i++) {
    setupCodeDetail(details[i]);
  }

  function setupCodeDetail(figure) {
    var caption = figure.querySelector('figcaption'),
        code = figure.querySelector('code'),
        lines = parseInt(figure.getAttribute('data-lines'), 10);

    if (navigator.clipboard && caption && code) {
      var copy = document.createElement('button');
      copy.type = 'button';
      copy.className = 'code-detail__button';
      copy.textContent = 'Copy';
      copy.setAttribute('aria-live', 'polite');
      copy.onclick = function () {
        navigator.clipboard.writeText(code.textContent).then(function () {
          copy.textContent = 'Copied';
          setTimeout(function () {
            copy.textContent = 'Copy';
          }, 2000);
        });
      };
      caption.appendChild(copy);
    }

    if (lines > COLLAPSE_AFTER) {
      var toggle = document.createElement('button');
      toggle.type = 'button';
      toggle.className = 'code-detail__toggle';
      toggle.setAttribute('aria-expanded', 'false');
      toggle.textContent = 'Show all ' + lines + ' lines';
      figure.className += ' is-collapsed';
      toggle.onclick = function () {
        var collapsed = figure.className.indexOf('is-collapsed') !== -1;
        figure.className = collapsed ?
            figure.className.replace(' is-collapsed', '') : figure.className + ' is-collapsed';
        toggle.setAttribute('aria-expanded', collapsed ? 'true' : 'false');
        toggle.textContent = collapsed ? 'Show fewer lines' : 'Show all ' + lines + ' lines';
      };
      figure.appendChild(toggle);
    }
  }

  // filter the blog index by type
  var filter = document.querySelector('.blog-filter');
  if (filter) {
    var rows = document.querySelectorAll('.blog-index tbody tr'),
        inputs = filter.querySelectorAll('input[name="kind"]');
    filter.removeAttribute('hidden');
    for (var j = 0; j < inputs.length; j++) {
      inputs[j].onchange = function () {
        var kind = this.value;
        for (var k = 0; k < rows.length; k++) {
          rows[k].hidden = kind !== '' && rows[k].getAttribute('data-kind') !== kind;
        }
      };
    }
  }
});
