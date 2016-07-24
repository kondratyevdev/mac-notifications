'use strict';

let nativeModule = require('./build/Release/mac-notifications');

module.exports = {

  initializeCallback: function(callback) {
    nativeModule.initializeCallback(function(notificationJSON) {
      if (callback != null) {
        let notification = JSON.parse(notificationJSON);

        let args = Array.from(arguments)
        args[0] = notification

        callback.apply(callback, args)
      }
    });
  },

  show: function(options) {
    let json = JSON.stringify(options);
    nativeModule.showNotification(json);
  }

}