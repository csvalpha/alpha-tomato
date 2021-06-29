<template lang="html">
  <b-row class="order-history no-gutters">
    <b-col>
      <b-table show-empty :busy.sync="isLoading" :items="activityProvider" :fields="fields"
               no-provider-sorting sort-by="start_time" sort-desc>

        <template v-slot:cell(order_total)="row">
          {{doubleToCurrency(row.item.order_total)}}
          <span class="pull-right">
            <i @click.stop="row.toggleDetails" :class="['order-history--details-expand', 'fa', 'fa-lg', 'ps-2', row.detailsShowing ? 'fa-chevron-circle-up' : 'fa-chevron-circle-down']"></i>
          </span>
        </template>

        <template v-slot:empty>
          <p class="my-1 text-center">
            <em>Er zijn geen bestellingen om weer te geven</em>
          </p>
        </template>

        <template slot="row-details" slot-scope="row">
          <ActivityOrderHistory :activity="row.item" :user="user" />
        </template>
      </b-table>

      <spinner class="pt-2 pb-3 m-auto" size="large" v-if="isLoading" />
    </b-col>
  </b-row>
</template>

<script>
  import Spinner from 'vue-simple-spinner';
  import ActivityOrderHistory from './activityorderhistory.vue';
  import axios from 'axios';
  import moment from 'moment';

  export default {
    props: {
      user: {
        type: Object,
        required: true
      },
    },

    data: function () {
      return {
        isLoading: false,
        fields: [
          {
            key: 'start_time',
            label: 'Datum',
            sortable: true,
            formatter: this.formatDate
          },
          {
            key: 'title',
            label: 'Titel',
            sortable: false
          },
          {
            key: 'order_total',
            label: 'Totaal',
            sortable: false
          }
        ]
      };
    },

    methods: {
      activityProvider() {
        let promise = axios.get('/users/'+this.user.id+'/activities');

        return promise.then((response) => {
          return response.data;
        }, () => {
          return [];
        });
      },

      doubleToCurrency(price) {
        return `€ ${parseFloat(price).toFixed(2)}`;
      },

      formatDate(time) {
        return moment(time).format('DD-MM-YY HH:mm');
      }
    },

    components: {
      Spinner,
      ActivityOrderHistory
    }
  };
</script>
