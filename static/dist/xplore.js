// Generated by CoffeeScript 1.12.7
var csv2Array;

csv2Array = function(strData, strDelimiter) {
  var arrData, arrMatches, objPattern, strMatchedDelimiter, strMatchedValue;
  strDelimiter = strDelimiter || ',';
  objPattern = new RegExp('(\\' + strDelimiter + '|\\r?\\n|\\r|^)' + '(?:"([^"]*(?:""[^"]*)*)"|' + '([^"\\' + strDelimiter + '\\r\\n]*))', 'gi');
  arrData = [[]];
  arrMatches = null;
  while (arrMatches = objPattern.exec(strData)) {
    strMatchedDelimiter = arrMatches[1];
    if (strMatchedDelimiter.length && strMatchedDelimiter !== strDelimiter) {
      arrData.push([]);
    }
    strMatchedValue = void 0;
    if (arrMatches[2]) {
      strMatchedValue = arrMatches[2].replace(new RegExp('""', 'g'), '"');
    } else {
      strMatchedValue = arrMatches[3];
    }
    arrData[arrData.length - 1].push(strMatchedValue);
  }
  return arrData;
};

window.xplore = {
  util: {
    csv2Array: csv2Array
  }
};
