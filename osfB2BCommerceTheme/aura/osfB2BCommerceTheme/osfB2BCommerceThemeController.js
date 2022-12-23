({
	setup: function (component, event, helper) { },
	scriptsLoaded: function (component, event) {
		window.lb2bStore = {
			LB2B: component,
			runsInBuilder: window.location.href.search("livepreview.salesforce") > -1
		};
		var colorShadesToCreate = [
			{
				base: getComputedStyle(document.body).getPropertyValue('--lwc-colorBackgroundButtonBrand'),
				shades: [
					{
						brightnessDiff: 10,
						varName: 'actionShade1'
					},
					{
						brightnessDiff: 20,
						varName: 'actionShade2'
					}
				]
			},
			{
				base: getComputedStyle(document.body).getPropertyValue('--lwc-colorBorder'),
				shades: [
					{
						brightnessDiff: -10,
						varName: 'darkGrey'
					},
					{
						brightnessDiff: 2,
						varName: 'lightGrey'
					},
					{
						brightnessDiff: 35,
						varName: 'brightGrey'
					},
					{
						brightnessDiff: 43,
						varName: 'brightGrey1'
					},
					{
						brightnessDiff: 47,
						varName: 'brightGrey2'
					}
				]
			},
			{
				base: getComputedStyle(document.body).getPropertyValue('--lwc-colorTextError'),
				shades: [
					{
						brightnessDiff: 10,
						varName: 'errorShade1'
					},
					{
						brightnessDiff: 20,
						varName: 'errorShade2'
					}
				]
			},
			{
				base: getComputedStyle(document.body).getPropertyValue('--lwc-colorTextSuccess'),
				shades: [
					{
						brightnessDiff: 10,
						varName: 'successShade1'
					},
					{
						brightnessDiff: 20,
						varName: 'successShade2'
					}
				]
			},
			{
				base: getComputedStyle(document.body).getPropertyValue('--lwc-colorTextButtonBrand'),
				shades: [
					{
						brightnessDiff: 0,
						opacity: 0.1,
						varName: 'overlayTextColor01'
					},
					{
						brightnessDiff: 0,
						opacity: 0.2,
						varName: 'overlayTextColor02'
					}
				]
			}
		];

		function attachColorVariables(colorsArr) {
			var extravars = document.querySelector(':root');

			colorsArr.forEach(function (colorsObj) {
				var baseColor = colorsObj.base.indexOf('rgb') == -1 ? hexToRgb(colorsObj.base) : colorsObj.base;
				colorsObj.shades.forEach(function (shadesObj) {
					extravars.style.setProperty('--b2btheme_' + shadesObj.varName, getColorShade(baseColor, shadesObj.brightnessDiff, shadesObj.opacity));
				});
			});
		};

		function hexToRgb(hex) {
			var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
			return result ? 'rgb(' + parseInt(result[1], 16) + ',' + parseInt(result[2], 16) + ',' + parseInt(result[3], 16) + ')' : null;
		}

		function getColorShade(rgbColor, brightnessDiff, opacity) {
			var rgbArr = rgbColor.replace(/rgb/i, "")
				.replace(/[()]/g, '')
				.split(',')
				.map(function (elem) {
					return parseInt(elem);
				});

			var baseHSVArr = rgbToHsv(rgbArr[0], rgbArr[1], rgbArr[2]);
			var brightnes = baseHSVArr[2] + brightnessDiff;

			baseHSVArr[2] = brightnes < 100 ? brightnes : 100;

			var rgbArr = hsvToRgb(baseHSVArr[0], baseHSVArr[1], baseHSVArr[2]);
			rgbArr.push(opacity ? opacity : 1);

			return 'rgba(' + rgbArr.join(',') + ')';
		};

		function rgbToHsv(r, g, b) {
			let rabs, gabs, babs, rr, gg, bb, h, s, v, diff, diffc, percentRoundFn;
			rabs = r / 255;
			gabs = g / 255;
			babs = b / 255;
			v = Math.max(rabs, gabs, babs),
				diff = v - Math.min(rabs, gabs, babs);
			diffc = c => (v - c) / 6 / diff + 1 / 2;
			percentRoundFn = num => Math.round(num * 100) / 100;
			if (diff == 0) {
				h = s = 0;
			} else {
				s = diff / v;
				rr = diffc(rabs);
				gg = diffc(gabs);
				bb = diffc(babs);
				if (rabs === v) {
					h = bb - gg;
				} else if (gabs === v) {
					h = (1 / 3) + rr - bb;
				} else if (babs === v) {
					h = (2 / 3) + gg - rr;
				}
				if (h < 0) {
					h += 1;
				} else if (h > 1) {
					h -= 1;
				}
			}
			return [
				Math.round(h * 360),
				percentRoundFn(s * 100),
				Math.round(percentRoundFn(v * 100))
			];
		}

		function hsvToRgb(h, s, v) {
			var r, g, b;
			var i;
			var f, p, q, t;

			h = Math.max(0, Math.min(360, h));
			s = Math.max(0, Math.min(100, s));
			v = Math.max(0, Math.min(100, v));

			s /= 100;
			v /= 100;
			if (s == 0) {
				r = g = b = v;
				return [
					Math.round(r * 255),
					Math.round(g * 255),
					Math.round(b * 255)
				];
			}
			h /= 60;
			i = Math.floor(h);
			f = h - i;
			p = v * (1 - s);
			q = v * (1 - s * f);
			t = v * (1 - s * (1 - f));
			switch (i) {
				case 0:
					r = v;
					g = t;
					b = p;
					break;
				case 1:
					r = q;
					g = v;
					b = p;
					break;
				case 2:
					r = p;
					g = v;
					b = t;
					break;
				case 3:
					r = p;
					g = q;
					b = v;
					break;
				case 4:
					r = t;
					g = p;
					b = v;
					break;
				default:
					r = v;
					g = p;
					b = q;
			}
			return [
				Math.round(r * 255),
				Math.round(g * 255),
				Math.round(b * 255)
			];
		}
		attachColorVariables(colorShadesToCreate);
	},

	handleRouteChange: function (component, event) {
		var pageLang = document
			.getElementsByTagName("html")[0]
			.getAttribute("lang");
		var bodyClass = document.querySelector("body").classList;
		var themeClass = document.getElementsByClassName("cB2bTheme")[0];
		var themeBody = component.find("body").getElement();
		themeBody ? themeBody.classList = 'body ' + bodyClass : null;
		themeClass ? themeClass.classList.add(pageLang) : null;
	}
});