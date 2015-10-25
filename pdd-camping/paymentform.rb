module PaymentForm
  def paymentform(amount)
    stripecode = %q{
Stripe.setPublishableKey('pk_test_oLIm1R9BjDo6ymTGBemqbK1A');
jQuery(function($) {
  var pay = function(event) {
    var form = $('#payment');
    form.find('button').prop('disabled', true);
    var token = Stripe.card.createToken(form, function (status, response) {
      console.log(response);
      if (response.error) {
         form.find('.payment-errors').text(response.error.message);
         form.find('button').prop('disabled', false);
      } else {
         var token = response.id;
         console.log(token);
         form.append('<input type="hidden" name="stripeToken">')
         $('#payment input[name=stripeToken]').val(token);
         form.get(0).submit();
      }
    });
    return false;
  }
  $('#payment').submit(pay);
});
}
    script :src => 'https://js.stripe.com/v2/', :type => 'text/javascript'
    script :src => 'http://code.jquery.com/jquery-2.1.3.js', :type => 'text/javascript'
    script { stripecode }

    form.payment! :method => 'POST' do
      span.paymenterrors!
      input :type => 'hidden', :name => 'amount', :value => amount
      div :class => 'form-row' do
        label do
          text "Credit card number"
          input :type => 'text', :size => '20', :'data-stripe' => 'number'
        end
      end
      div :class => 'form-row' do
        label do
          text "CVV code"
          input :type => 'text', :size => '3', :'data-stripe' => 'cvc'
        end
      end
      div :class => 'form-row' do
        label do
          text "Expiration date"
          input :type => 'text', :size => '2', :'data-stripe' => 'exp-month'
          input :type => 'text', :size => '4', :'data-stripe' => 'exp-year'
        end
      end
      button "Pay", :type => 'submit'
    end
  end
end
