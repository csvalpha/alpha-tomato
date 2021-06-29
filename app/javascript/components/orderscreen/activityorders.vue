<template lang="html">
  <b-row class="order-history no-gutters">
    <b-col>
      <b-table show-empty :busy.sync="isLoading" :items="ordersProvider" :fields="fields"
        no-provider-sorting sort-by="created_at" sort-desc>

        <template v-slot:cell(user)="row">
          <span v-if="row.item.user">{{row.item.user.name}}</span>
          <span v-else-if="row.item.paid_with_pin">Gepind</span>
          <span v-else-if="row.item.paid_with_cash">Contant betaald</span>
        </template>

        <template v-slot:cell(order_total)="row">
          <span class="pull-right">
            {{doubleToCurrency(row.item.order_total)}}
            <i @click.stop="row.toggleDetails" :class="['order-history--details-expand', 'fa', 'fa-lg', 'ps-2', row.detailsShowing ? 'fa-chevron-circle-up' : 'fa-chevron-circle-down']"></i>
          </span>
        </template>

        <template v-slot:empty>
          <p class="my-1 text-center">
            <em>Er zijn geen bestellingen om weer te geven</em>
          </p>
        </template>

        <ProductTable slot="row-details" slot-scope="row" editable :order="row.item" :activity="activity" />
      </b-table>

      <spinner class="pt-2 pb-3 m-auto" size="large" v-if="isLoading" />
    </b-col>
  </b-row>
</template>

<script>
import Spinner from 'vue-simple-spinner';
import axios from 'axios';
import moment from 'moment';
import ProductTable from '../producttable.vue';

export default {
  props: {
    activity: {
      type: Object,
      required: true
    },
    editable: {
      type: Boolean,
      default: false
    },
    expand_first: {
      type: Boolean,
      default: false
    }
  },

  data: function () {
    return {
      isLoading: false,
      fields: [
        {
          key: 'id',
          label: '#',
          sortable: true,
          thClass: 'text-center',
          tdClass: 'text-center',
          isRowHeader: true
        },
        {
          key: 'created_at',
          label: 'Tijdstip',
          sortable: true,
          formatter: this.formatDate
        },
        {
          key: 'user',
          label: 'Gebruiker',
          sortable: true,
          tdClass: (user) => user ? '' : 'font-italic'
        },
        {
          key: 'order_total',
          label : 'Bedrag',
          sortable: false,
          thClass: 'text-end pe-4'
        }
      ]
    };
  },

  methods: {
    ordersProvider() {
      let params;
      if (this.activity) {
        params = { activity_id: this.activity.id }
      } else if (this.user) {
        params = { user_id: this.user.id }
      }

      let promise = axios.get('/orders', { params });

      return promise.then((response) => {
        const orders = response.data;
        orders.map((order, index) => {
          order._showDetails = (this.expand_first && index === orders.length - 1);
          order.order_rows.map(row => { row.editing = false });
        });

        return orders;
      }, () => {
        return [];
      });
    },

    doubleToCurrency(price) {
      return `€ ${parseFloat(price).toFixed(2)}`;
    },

    formatDate(time) {
      return moment(time).format('DD-MM HH:mm:ss');
    }
  },

  components: {
    Spinner,
    ProductTable
  }
};
</script>
