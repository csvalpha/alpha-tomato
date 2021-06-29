<template lang="html">
  <b-container slot="row-details" slot-scope="row">
    <b-row class="b-table-details--header px-2 py-1 mb-2">
      <b-col sm="5">product</b-col>
      <b-col sm="2" class="text-end">aantal</b-col>
      <b-col sm="3" class="text-end">prijs per stuk</b-col>
      <b-col sm="2" class="text-end pe-3">
        <span :class="editable ? 'pe-3' : ''">totaal</span>
      </b-col>
    </b-row>
    <b-row v-for="orderRow in order.order_rows" class="b-table-details--item px-2" :key="orderRow.id">
      <b-col sm="5" >
        {{orderRow.product.name}}
        <div v-if="orderRowErrors[orderRow.id]">
          <small class="text-danger"><em>{{orderRowErrors[orderRow.id]}}</em></small>
        </div>
      </b-col>
      <b-col sm="2" class="text-end">
        <template v-if="editable && orderRow.editing">
          <i @click="increaseProductCount(orderRow)"
             class="fa fa-plus-square-o order-history--item-count"></i>
          <span class="px-2">{{orderRow.product_count}}</span>
          <i @click="decreaseProductCount(orderRow)"
             class="fa fa-minus-square-o order-history--item-count"></i>
        </template>
        <template v-else>
          {{orderRow.product_count}}
        </template>
      </b-col>
      <b-col sm="3" class="text-end">
        {{doubleToCurrency(orderRow.price_per_product)}}
      </b-col>
      <b-col sm="2" :class="['text-end', editable ? 'pe-1' : 'pe-3']">
        {{doubleToCurrency(orderRow.product_count * orderRow.price_per_product)}}
        <template v-if="editable">
          <i v-if="orderRow.editing" @click="saveOrderRow(orderRow)" class="order-history--item-save fa fa-save ps-3"></i>
          <i v-else @click="editOrderRow(orderRow)" class="order-history--item-edit fa fa-pencil ps-3"></i>
        </template>
      </b-col>
    </b-row>
  </b-container>
</template>

<script>
  import axios from 'axios';

  export default {
    props: {
      activity: {
        type: Object
      },
      order: {
        type: Object,
        required: true
      },
      editable: {
        type: Boolean,
        default: false
      }
    },
    data: function () {
      return {
        orderRowErrors: {}
      }
    },
    methods: {
      doubleToCurrency(price) {
        return `€ ${parseFloat(price).toFixed(2)}`;
      },

      editOrderRow(orderRow) {
        orderRow.editing = true;
      },

      saveOrderRow(orderRow) {
        const newOrder = {
          order_rows_attributes: [ {
            id: orderRow.id,
            product_count: orderRow.product_count,
          } ]
        }

        if (this.activity.id) newOrder.activity_id = this.activity.id;

        axios.patch(`/orders/${this.order.id}`, newOrder).then((response) => {
          const updatedOrder = response.data;

          this.order.order_total = updatedOrder.order_total;

          orderRow.editing = false;
        }, (error) => {
          let errorMessage = 'Er is iets misgegaan bij het opslaan van deze rij';
          if (error.response && error.response.data['order_rows.product_count']) {
            errorMessage = `Aantal ${error.response.data['order_rows.product_count']}`
          }

          this.$set(this.orderRowErrors, orderRow.id, errorMessage);
        })
      },

      increaseProductCount(orderRow) {
        orderRow.product_count += 1;
      },

      decreaseProductCount(orderRow) {
        if (orderRow.product_count > 0) {
          orderRow.product_count -= 1;
        }
      },
    },
  }
</script>
