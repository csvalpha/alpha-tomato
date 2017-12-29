import Vue from 'vue/dist/vue.esm';
import TurbolinksAdapter from 'vue-turbolinks';
import VueResource from 'vue-resource';

Vue.use(TurbolinksAdapter);
Vue.use(VueResource);

document.addEventListener('turbolinks:load', () => {
  Vue.http.headers.common['X-CSRF-TOKEN'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

  var element = document.getElementById('order-screen');
  if (element != null) {
    var users = JSON.parse(element.dataset.users);
    var productPrices = JSON.parse(element.dataset.productPrices);
    var activity = JSON.parse(element.dataset.activity);

    window.flash = function(message, actionText, type) {
      const event = new CustomEvent('flash', { detail: { message: message, actionText: actionText, type: type } } );
      dispatchEvent(event);
    };

    var orderscreenFlash = {
      template: '#orderscreen-flash',
      props: {
        timeout: {
          type: Number,
          default: 3000
        },
        transition: {
          type: String,
          default: 'slide-fade'
        },
        types: {
          type: Object,
          default: () => ({
            base:    'flash',
            success: 'flash-success',
            error:   'flash-danger',
            warning: 'flash-warning',
            info:    'flash-info'
          })
        },
        icons: {
          type: Object,
          default: () => ({
            base:    'fa fa-lg mr-2',
            error:   'fa-exclamation-circle',
            success: 'fa-check-circle',
            info:    'fa-info-circle',
            warning: 'fa-exclamation-circle',
          })
        },
      },

      data: () => ({
        notificationQue: [],
        activeNotification: null,
        timeoutVar: null,
        notificationCounter: 1
      }),

      created() {
        addEventListener('flash', (flash) => {
          this.flash(flash.detail.message, flash.detail.actionText, flash.detail.type);
        });
      },

      methods: {
        flash(message, actionText, type) {
          const flashData = {
            message: `${message} #${this.notificationCounter}`,
            actionText: actionText,
            type: type,
            typeObject: this.classes(this.types, type),
            iconObject: this.classes(this.icons, type)
          };
          this.notificationCounter++;
          this.notificationQue.push(flashData);
          this.notificationQueChanged();
        },

        classes(propObject, type) {
          let classes = {};
          if(propObject.hasOwnProperty('base')) {
            classes[propObject.base] = true;
          }
          if (propObject.hasOwnProperty(type)) {
            classes[propObject[type]] = true;
          }
          return classes;
        },

        hideCurrentNotification() {
          this.activeNotification = null;
          this.notificationQueChanged();
        },

        notificationQueChanged() {
          if (!this.activeNotification && this.notificationQue.length > 0) {
            const newNotification = this.notificationQue.shift();
            this.activeNotification = null;

            // Small delay for UX purposes
            setTimeout(() => {
              this.activeNotification = newNotification;
            }, 100);
            this.timeoutVar = setTimeout(this.hideCurrentNotification, this.timeout);
          }
        },

        mouseOver() {
          clearTimeout(this.timeoutVar);
        },

        mouseLeave() {
          this.timeoutVar = setTimeout(this.hideCurrentNotification, this.timeout);
        }
      }
    };

    var userSelection = {
      template: '#user-selection',
      props: {
        selectedUser: null,
        users: {
          type: Array,
          required: true
        }
      },

      data: () => {
        return {
          highlightedUserIndex: -1,
          userQuery: '',
          suggestedUsers: users
        };
      },

      methods: {
        doubleToCurrency(price) {
          return `€${parseFloat(price).toFixed(2)}`;
        },

        queryChange() {
          this.suggestedUsers = this.searchUsersResult();
          this.resetHighlight();
        },

        searchUsersResult: function() {
          return this.users.filter((user) => {
            return user.name.toLowerCase().indexOf(this.userQuery.toLowerCase()) !== -1;
          });
        },

        resetHighlight() {
          if (this.userQuery.length === 0) {
            this.highlightedUserIndex = -1;
          } else {
            this.highlightedUserIndex = 0;
          }
        },

        increaseHighlightedUserIndex() {
          if ((this.highlightedUserIndex + 1) < this.suggestedUsers.length) {
            this.highlightedUserIndex++;
          }
        },

        decreaseHighlightedUserIndex() {
          if ((this.highlightedUserIndex) > 0) {
            this.highlightedUserIndex--;
          }
        },

        selectUser(user) {
          this.userQuery = '';
          this.queryChange();
          this.$emit('updateuser', user);
        },

        selectHighlightedUser() {
          if (this.searchUsersResult(this.userQuery).length > 0){
            var user = this.searchUsersResult(this.userQuery)[this.highlightedUserIndex];
            this.selectUser(user);
          }
        }
      }
    };

    new Vue({
      el: element,
      data: () => {
        return {
          users: users,
          productPrices: productPrices,
          activity: activity,
          selectedUser: null,
          orderRows: []
        };
      },
      methods: {
        sendFlash: function(message, actionText, type) {
          /* eslint-disable no-undef */
          flash(message, actionText, type);
          /* eslint-enable */
        },

        doubleToCurrency(price) {
          return `€${parseFloat(price).toFixed(2)}`;
        },

        setUser(user) {
          this.selectedUser = user;
        },

        selectProduct(productPrice) {
          if (this.selectedUser) {
            const orderRow = this.orderRows.filter((row) => { return row.productPrice === productPrice; })[0];

            if (orderRow) {
              orderRow.amount++;
            } else {
              this.orderRows.push({productPrice: productPrice, amount: 1});
            }
          }
        },

        dropOrderRow(index) {
          this.$delete(this.orderRows, index);
        },

        orderTotal() {
          return this.orderRows.map(function(row) {
            return row.productPrice.price * row.amount;
          }).reduce((total, amount) => total + amount, 0);
        },

        decreaseRowAmount(orderRow) {
          if (orderRow.amount > 0) {
            orderRow.amount--;
          }
        },

        increaseRowAmount(orderRow) {
          orderRow.amount++;
        },

        confirmOrder() {
          console.log('Order confirmed');
        }
      },

      components: {
        'orderscreen-flash': orderscreenFlash,
        'user-selection': userSelection
      }
    });
  }
});
