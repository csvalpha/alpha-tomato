<template lang="html">
  <div class="user-details" v-if="selectedUser">
    <div class="user-details-user container">
      <div class="row py-3">
        <div class="user-details-avatar col-4 px-1">
          <img :src="selectedUser.avatar_thumb_or_default_url" alt="User picture"
               onerror="this.src = '/images/avatar_thumb_default.png';"
               class='img-thumbnail rounded-circle'>
        </div>

        <div class="user-details-name col-8">
          <h3 class="mb-3">
            {{selectedUser.name}}

            <span class="pull-right px-1 user-details-close"
                  title="Deselect (Esc)"
                  @click="selectUser(null)">
              <i class="fa fa-times-circle"></i>
            </span>
          </h3>

          <h3 :class="{ 'text-danger' : (selectedUser.credit <= 0) }">
            {{doubleToCurrency(selectedUser.credit)}}
          </h3>

          <b-btn variant="secondary" v-b-modal.credit-mutation-modal>
            <i class="fa fa-money me-1"></i>
            Geld inleggen
          </b-btn>
        </div>
      </div>
    </div>
  </div>

  <div class="user-details" v-else-if="payWithCash || payWithPin">
    <div class="user-details-user container py-3">
      <div class="row justify-content-end">
        <div class="col-10 d-flex flex-column align-items-center" v-if="payWithCash">
          <h1 class="display-3 py-2">
            <i class="fa fa-money fa-lg"></i>
          </h1>

          <h4 class="font-weight-light text-center">
            <em>Bestelling contant betalen</em>
          </h4>
        </div>
        <div class="col-10 d-flex flex-column align-items-center" v-else-if="payWithPin">
          <h1 class="display-3 py-2">
            <i class="fa fa-credit-card fa-lg"></i>
          </h1>

          <h4 class="font-weight-light text-center">
            <em>Bestelling met pin betalen</em>
          </h4>
        </div>

        <h3 class="col-1 pe-2 user-details-close" @click="selectUser(null)">
          <i class="fa fa-times-circle pull-right"></i>
        </h3>
      </div>
    </div>
  </div>

  <div class="user-details" v-else>
    <div class="user-details-search">
      <input type="text" class="form-control form-control-lg" ref="userSearchBar" v-model="userQuery"
             placeholder="Gebruiker zoeken" @input="queryChange" @keyup.enter.prevent="selectHighlightedUser"
             @keyup.up="decreaseHighlightedUserIndex" @keyup.down="increaseHighlightedUserIndex" autofocus>

      <button class="btn btn-secondary mt-3" @click="selectCash">
        <i class="fa fa-money me-1"></i>
        Betaal contant
      </button>
      <button class="btn btn-secondary mt-3" @click="selectPin">
        <i class="fa fa-credit-card me-1"></i>
        Betaal met pin
      </button>
    </div>

    <div class="user-details-suggestions container">
      <div class="user-details-suggestions-user row justify-content-center align-items-center"
           v-for="(user, index) in suggestedUsers" :key="index" :class="{ highlight : (highlightedUserIndex == index) }"
           @click="selectUser(user)" @mouseover="highlightedUserIndex = -1" @mouseleave="resetHighlight"
           :ref="`suggestedUser${index}`">
        <div class="user-details-suggestions-user-avatar col-4">
          <img class="img-thumbnail rounded-circle"
               :src="user.avatar_thumb_or_default_url"
               onerror="this.src = '/images/avatar_thumb_default.png';">
        </div>

        <h4 class="user-details-suggestions-user-name col-8 m-0" v-html="$options.filters.highlightedName(user.name, userQuery)" />
      </div>
    </div>
  </div>
</template>

<script>
import removeAccents from 'remove-accents';
import match from 'autosuggest-highlight/match';
import parse from 'autosuggest-highlight/parse';

export default {
  props: {
    selectedUser: null,
    payWithCash: false,
    payWithPin: false,
    users: {
      type: Array,
      required: true
    }
  },

  data: function () {
    return {
      highlightedUserIndex: -1,
      userQuery: '',
      suggestedUsers: this.users
    };
  },

  watch: {
    'users': 'queryChange'
  },

  updated: function() {
    const input = this.$refs.userSearchBar;
    input && input.focus();
  },

  filters: {
    highlightedName(name, query) {
      if (query === '') {
        return name
      };

      let result = '';
      parse(name, match(name, query)).map((string) => {
        if(string.highlight) {
          result += `<strong class="highlight">${string.text}</strong>`;
        } else {
          result += string.text;
        }
      });

      return result;
    },
  },

  methods: {
    doubleToCurrency(price) {
      return `€ ${parseFloat(price).toFixed(2)}`;
    },

    queryChange() {
      this.suggestedUsers = this.searchUsersResult();
      this.resetHighlight();
    },

    normalizeString(string) {
      return removeAccents(string).toLowerCase();
    },

    searchUsersResult: function() {
      return this.users.filter((user) => {
        return this.normalizeString(user.name).indexOf(this.normalizeString(this.userQuery)) !== -1;
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
        this.scrollToUser();
      }
    },

    decreaseHighlightedUserIndex() {
      if ((this.highlightedUserIndex) > 0) {
        this.highlightedUserIndex--;
        this.scrollToUser();
      }
    },

    scrollToUser() {
      this.$refs[`suggestedUser${this.highlightedUserIndex}`][0].scrollIntoView({block: 'nearest'});
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
    },

    selectCash() {
      this.userQuery = '';
      this.queryChange();
      this.$emit('selectcash', 'pay_with_cash');
    },

    selectPin() {
      this.userQuery = '';
      this.queryChange();
      this.$emit('selectpin', 'pay_with_pin');
    }
  }
};
</script>
