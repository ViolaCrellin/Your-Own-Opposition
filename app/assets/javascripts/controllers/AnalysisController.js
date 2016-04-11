
UrlsApp.controller('AnalysisController', ['$resource', function($resource) {
  var self = this;
  var analysisResource = $resource('http://localhost:3000/analysis');
  var analysisResponse = [];
  var analysisResponseMessage = "";
  var breakdownResponse = [];
  var sources = [];
  var percentageRead = [];
  var suggestionsResponse = [];
  var sourceSuggestion = [];
  var urlLinks = [];
  var articleImages = [];
  var articleTitles = [];
  var keywords = [];
  var keyword = "";
  var topicKeywords = [];
  var topKeywords = [];
  var mostRelevant = [];
  var topicValues = [];
  var numberToRead = [];
  var quantity = "";
  self.showUserUrls = false;


  self.toggleShowRecentUrls = function() {
    self.showUserUrls = !self.showUserUrls;
  };


  self.showBias = function() {
    self.loaded = true;
    analysisResource.get().$promise.then(function(data){
      console.log(data);
      self.analysisResponse = data.bias.political_leaning;
      self.analysisResponseMessage = data.bias.bias_message;
    });
  };

  self.hideBias = function() {
    self.loaded = false;
  };

  self.showBreakDown = function(){
    self.furtherInfoLoaded = true;
    analysisResource.get().$promise.then(function(data){
      self.breakdownResponse = data.media_diet;
      self.sources = Object.keys(self.breakdownResponse);
      self.percentageRead = self.sources.map(function (key) {
                        return self.breakdownResponse[key];
                        });
  });

  self.hideBreakDown = function() {
    self.furtherInfoLoaded = false;
  };
};

var suggestionsResource = $resource('http://localhost:3000/suggestions');
var urlsResource = $resource('http://localhost:3000/urls');


 self.showSuggestions = function() {
   self.suggestionsLoaded = true;
   suggestionsResource.get().$promise.then(function(data){
     self.numberToRead = data.best_source[1];
     self.keyword = data.best_source[0];
     self.topicKeyword = data.top_topics[0];
   });
 };



 self.articleLoaded = false;
 self.getSuggestions = function() {
   self.suggestionsLoaded = false;
   self.searchingForLink = true;

  var webhoseResource = $resource("https://webhose.io/search?token=b68bbb9d-dd4d-4179-95c1-d60a3cdbd303&format=json&q=politics%20" + self.topicKeyword + "%20site%3A"+ self.keyword + ".co.uk");
   webhoseResource.get().$promise.then(function(data) {

     self.articleLoaded = true;
     self.articles = data.posts;
     self.urlLinks = self.articles.map(function (article){
                      return article.url;
                      });
    self.articleImages = self.articles.map(function (article){
                     return article.thread.main_image;
                     });
    self.articleTitles = self.articles.map(function (article){
                     return article.title;
                     });
    self.quantity = self.numberToRead[0] - 1;
     self.searchingForLink = false;
   });
 };




}]);
