Rails.application.routes.draw do

  #web display
  root 'registe#index'

  get 'admin_manage/sign_index' => 'admin_manage#sign_index'
  get 'admin_manage/sign_in' => 'admin_manage#sign_in'
  post 'admin_manage/sign_in' => 'admin_manage#sign_in'
  post 'admin_manage/sign_out' => 'admin_manage#sign_out'
  get 'admin_manage/passwd_new' => 'admin_manage#passwd_new'
  post 'admin_manage/passwd_modify' => 'admin_manage#passwd_modify'

  get 'registe/index' => 'registe#index'
  get 'registe/:userid/show' => 'registe#show'

  get 'finance_water/:id/show' => 'finance_water#show', as: :show_user_finance_water
  get 'finance_water/:id/new' => 'finance_water#new',as: :new_user_finance_water
  get 'finance_water/:id/export' => 'finance_water#export', as: :export_user_finance_water
  post 'finance_water/:userid/modify_web' => 'finance_water#modify_web'

  get 'pay/:userid/show' => 'online_pay#show', as: :show_user_online_pay
  get 'pay/:online_pay_id/show_single_detail' => 'online_pay#show_single_detail', as: :show_single_online_pay
  get 'pay/index' => 'online_pay#index', as: :index_online_pay
  get 'pay/export_index' => 'online_pay#export_index', as: :export_index_online_pay
  get 'pay/:userid/export' => 'online_pay#export', as: :export_user_online_pay

  get 'transaction_reconciliation/index' => 'transaction_reconciliation#index'
  get 'transaction_reconciliation/report' => 'transaction_reconciliation#report'
  get 'transaction_reconciliation/export' => 'transaction_reconciliation#export'
  get 'transaction_reconciliation/confirm_search' => 'transaction_reconciliation#confirm_search'
  post 'transaction_reconciliation/confirm' => 'transaction_reconciliation#confirm'
  post 'transaction_reconciliation/:transactionid/modify/:flag' => 'transaction_reconciliation#modify',as: :modify_transaction_reconciliation
  
  get 'upload_file/index' => 'upload_file#index'
  post 'upload_file/upload' => 'upload_file#upload'

  get 'admin_setting/index' => 'admin_setting#index'
  get 'admin_setting/:admin_name/show_authority' => 'admin_setting#show_authority',as: :show_authority_admin_setting
  get 'admin_setting/:admin_name/new_authority' => 'admin_setting#new_authority',as: :new_authority_admin_setting
  post 'admin_setting/:admin_name/modify_authority' => 'admin_setting#modify_authority',as: :modify_authority_admin_setting
  get 'admin_setting/:admin_name/new_country' => 'admin_setting#new_country',as: :new_country_admin_setting
  post 'admin_setting/:admin_name/modify_country' => 'admin_setting#modify_country',as: :modify_country_admin_setting

  post 'expection_handling/:online_pay_id/manual_payment' => 'expection_handling#manual_payment',as: :expection_handling_manual_payment
  post 'expection_handling/:online_pay_id/recall_notify' => 'expection_handling#recall_notify',as: :expection_handling_recall_notify
  
  get 'notice/index' => 'notice#index'
  post 'notice/:notice_id/handle' => 'notice#handle',as: :notice_handle

  get 'transaction_reconciliation/merchant_index' => 'transaction_reconciliation#merchant_index'
  get 'transaction_reconciliation/merchant_index_export' => 'transaction_reconciliation#merchant_index_export'
  get 'transaction_reconciliation/merchant_show' => 'transaction_reconciliation#merchant_show'
  get 'transaction_reconciliation/merchant_show_export' => 'transaction_reconciliation#merchant_show_export'

  #online_pay inteface use 
  post 'registe' => 'registe#create'
  get 'registe/:userid/obtain' => 'registe#obtain'

  post 'finance_water/:userid/modify' => 'finance_water#modify'
  get 'finance_water/:userid/water_obtain' => 'finance_water#water_obtain'
  post 'finance_water/refund' => 'finance_water#refund'
  post 'finance_water/correct' => 'finance_water#correct'
  post 'finance_water/invoice_merchant' => 'finance_water#invoice_merchant'

  post 'pay/:userid/submit' => 'online_pay#submit'
  # post 'pay/:userid/submit_creditcard' => 'online_pay#submit_creditcard'

  get 'pay/callback/alipay_oversea_return' => 'online_pay_callback#alipay_oversea_return'
  post 'pay/callback/alipay_oversea_notify' => 'online_pay_callback#alipay_oversea_notify'

  get 'pay/callback/alipay_transaction_return' => 'online_pay_callback#alipay_transaction_return'
  post 'pay/callback/alipay_transaction_notify' => 'online_pay_callback#alipay_transaction_notify'

  get 'pay/callback/paypal_return' => 'online_pay_callback#paypal_return'
  get 'pay/callback/paypal_abort' => 'online_pay_callback#paypal_abort'

  get 'pay/callback/sofort_return/:system/:order_no' => 'online_pay_callback#sofort_return'
  get 'pay/callback/sofort_abort/:system/:order_no' => 'online_pay_callback#sofort_abort'
  post 'pay/callback/sofort_notify' => 'online_pay_callback#sofort_notify'

  #reconciliation inteface use 
  get 'pay/:payment_system/get_reconciliation' => 'online_pay#get_bill_from_payment_system'


 
  #web display  ---  simulate interface 
  get 'simulation' => 'simulation#index'
  post 'simulation/simulate_pay' => 'simulation#simulate_pay'
  post 'simulation/simulate_pay_credit' => 'simulation#simulate_pay_credit'
  post 'simulation/simulate_post' => 'simulation#simulate_post'
  post 'simulation/simulate_get' => 'simulation#simulate_get'
  post 'simulation/simulate_finance_modify' => 'simulation#simulate_finance_modify'
  post 'simulation/simulate_registe' => 'simulation#simulate_registe'

  get 'simulation/callback_return' => 'simulation#callback_return'
  post 'simulation/callback_notify' => 'simulation#callback_notify'
  
  #reconciliation inteface call
  get 'simulation/simulate_reconciliation' => 'simulation#index_reconciliation'
  post 'simulation/simulate_reconciliation' => 'simulation#simulate_reconciliation'
  
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
