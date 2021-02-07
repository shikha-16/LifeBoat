<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!-- @formatter:off -->

<xsl:template name="login-sources">
  <folder name="com/examples/{$packageAppName}/{$subPackage}">
    <file name="MainLogin.java">
package <xsl:value-of select="$package"/>;

import android.app.Activity;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import androidx.annotation.NonNull;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import com.backendless.Backendless;
import com.backendless.BackendlessUser;
import com.backendless.async.callback.AsyncCallback;
import com.backendless.async.callback.BackendlessCallback;
import com.backendless.exceptions.BackendlessFault;

<xsl:if test="$facebookLogin">
import com.facebook.AccessToken;
import com.facebook.CallbackManager;
import com.facebook.FacebookCallback;
import com.facebook.FacebookException;
import com.facebook.login.LoginManager;
import com.facebook.login.widget.LoginButton;
</xsl:if>

<xsl:if test="$googleLogin">
import com.google.android.gms.auth.api.Auth;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.auth.api.signin.GoogleSignInResult;
import com.google.android.gms.common.Scopes;
import com.google.android.gms.common.SignInButton;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.common.api.OptionalPendingResult;
import com.google.android.gms.common.api.ResultCallback;
import com.google.android.gms.common.api.Scope;
import com.google.android.gms.common.api.Status;
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeTokenRequest;
import com.google.api.client.googleapis.auth.oauth2.GoogleTokenResponse;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.jackson2.JacksonFactory;
</xsl:if>

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;


public class MainLogin extends Activity {

	private boolean isLoggedInBackendless = false;
	private CheckBox rememberLoginBox;

	<xsl:if test="$backendlessLogin">
	// backendless
	private TextView registerLink, restoreLink;
	private EditText identityField, passwordField;
	private Button bkndlsLoginButton;
	</xsl:if>

	<xsl:if test="$twitterLogin">
	// twitter
	private Button loginTwitterButton;
	private boolean isLoggedInTwitter = false;
	</xsl:if>

	<xsl:if test="$googleLogin">
	// google
	private SignInButton loginGooglePlusButton;
	private final int RC_SIGN_IN = 112233; // arbitrary number
	private GoogleApiClient mGoogleApiClient;
	private String gpAccessToken = null;
	private boolean isLoggedInGoogle = false;
	</xsl:if>

	<xsl:if test="$facebookLogin">
	// facebook
	private LoginButton loginFacebookButton;
	private CallbackManager callbackManager;
	private String fbAccessToken = null;
	private boolean isLoggedInFacebook = false;
	</xsl:if>

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main_login);

		Backendless.initApp( this, getString(R.string.backendless_AppId), getString(R.string.backendless_ApiKey));
		Backendless.setUrl(getString(R.string.backendless_ApiHost));

		initUI();
		initUIBehaviour();

		Backendless.UserService.isValidLogin(new DefaultCallback&lt;Boolean&gt;(this) {
			@Override
			public void handleResponse(Boolean isValidLogin) {
				super.handleResponse(null);
				if (isValidLogin &amp;&amp; Backendless.UserService.CurrentUser() == null) {
					String currentUserId = Backendless.UserService.loggedInUser();

					if (!currentUserId.equals("")) {
						Backendless.UserService.findById(currentUserId, new DefaultCallback&lt;BackendlessUser&gt;(MainLogin.this, "Logging in...") {
							@Override
							public void handleResponse(BackendlessUser currentUser) {
									super.handleResponse(currentUser);
									isLoggedInBackendless = true;
									Backendless.UserService.setCurrentUser(currentUser);
									startLoginResult(currentUser);
								}
						});
					}
				}
				super.handleResponse(isValidLogin);
			}
		});
	}

	private void initUI() {
		rememberLoginBox = (CheckBox) findViewById( R.id.rememberLoginBox );

		<xsl:if test="$backendlessLogin">
		// backendless
		registerLink = (TextView) findViewById( R.id.registerLink );
		restoreLink = (TextView) findViewById( R.id.restoreLink );
		identityField = (EditText) findViewById( R.id.identityField );
		passwordField = (EditText) findViewById( R.id.passwordField );
		bkndlsLoginButton = (Button) findViewById( R.id.bkndlsLoginButton);
		</xsl:if>

		<xsl:if test="$twitterLogin">
		// twitter
		loginTwitterButton = (Button) findViewById(R.id.loginTwitterButton);
		</xsl:if>

		<xsl:if test="$googleLogin">
		// google
		loginGooglePlusButton = (SignInButton) findViewById(R.id.button_googlePlusLogin);
		</xsl:if>

		<xsl:if test="$facebookLogin">
		// facebook
		loginFacebookButton = (LoginButton) findViewById(R.id.button_FacebookLogin);
		</xsl:if>
	}

	private void initUIBehaviour() {
		<xsl:if test="$backendlessLogin">
		// backendless
		bkndlsLoginButton.setOnClickListener(new View.OnClickListener()
		{
			@Override
			public void onClick( View view )
			{
				onLoginWithBackendlessButtonClicked();
			}
		} );
		registerLink.setOnClickListener( new View.OnClickListener()
		{
			@Override
			public void onClick( View view )
			{
				onRegisterLinkClicked();
			}
		} );
		restoreLink.setOnClickListener( new View.OnClickListener()
		{
			@Override
			public void onClick( View view )
			{
				onRestoreLinkClicked();
			}
		} );
		</xsl:if>

		<xsl:if test="$twitterLogin">
		// twitter
		loginTwitterButton.setOnClickListener(new View.OnClickListener() {
			@Override
			public void onClick(View view) {
				onLoginWithTwitterButtonClicked();
			}
		});
		</xsl:if>

		<xsl:if test="$facebookLogin">
		// facebook
		callbackManager = configureFacebookSDKLogin();
		if (AccessToken.getCurrentAccessToken() != null)
		{
			isLoggedInFacebook = true;
			fbAccessToken = AccessToken.getCurrentAccessToken().getToken();
		}
		</xsl:if>

		<xsl:if test="$googleLogin">
		// google
		configureGooglePlusSDK();
		if (mGoogleApiClient.isConnected())
		{
			OptionalPendingResult pendingResult = Auth.GoogleSignInApi.silentSignIn(mGoogleApiClient);
			if (pendingResult.isDone())
				handleSignInResult((GoogleSignInResult) pendingResult.get());
		}
		</xsl:if>
	}

	private void startLoginResult(BackendlessUser user)
	{
		String msg = "ObjectId: " + user.getObjectId() + "\n"
				+ "UserId: " + user.getUserId() + "\n"
				+ "Email: " + user.getEmail() + "\n"
				+ "Properties: " + "\n";

		for (Map.Entry&lt;String, Object&gt; entry : user.getProperties().entrySet())
			msg += entry.getKey() + " : " + entry.getValue() + "\n";


		Intent intent = new Intent(this, LoginResult.class);
		intent.putExtra(LoginResult.userInfo_key, msg);
		intent.putExtra(LoginResult.logoutButtonState_key, true);
		startActivity(intent);
	}

	private void startLoginResult(String msg, boolean logoutButtonState)
	{
		Intent intent = new Intent(this, LoginResult.class);
		intent.putExtra(LoginResult.userInfo_key, msg);
		intent.putExtra(LoginResult.logoutButtonState_key, logoutButtonState);
		startActivity(intent);
	}

	<xsl:if test="$backendlessLogin">
	private void onLoginWithBackendlessButtonClicked()
	{
		String identity = identityField.getText().toString();
		String password = passwordField.getText().toString();
		boolean rememberLogin = rememberLoginBox.isChecked();

		Backendless.UserService.login( identity, password, new DefaultCallback&lt;BackendlessUser&gt;( MainLogin.this )
		{
			public void handleResponse( BackendlessUser backendlessUser )
			{
				super.handleResponse( backendlessUser );
				isLoggedInBackendless = true;
				startLoginResult(backendlessUser);
			}

			@Override
			public void handleFault(BackendlessFault fault) {
				super.handleFault(fault);
				startLoginResult(fault.toString(), false);
			}
		}, rememberLogin );
	}

	private void onRegisterLinkClicked()
	{
		startActivity( new Intent( this, RegisterActivity.class ) );
	}

	private void onRestoreLinkClicked()
	{
		startActivity( new Intent( this, RestorePasswordActivity.class ) );
	}
	</xsl:if>

	<xsl:if test="$twitterLogin">
	// ------------------------------ twitter ------------------------------
	private void onLoginWithTwitterButtonClicked() {
		Map&lt;String, String&gt; twitterFieldsMapping = new HashMap&lt;&gt;();
		twitterFieldsMapping.put("name", "name");
		boolean rememberLogin = rememberLoginBox.isChecked();

		Backendless.UserService.loginWithTwitter(MainLogin.this, twitterFieldsMapping, new BackendlessCallback&lt;BackendlessUser&gt;() {
			@Override
			public void handleResponse(BackendlessUser backendlessUser) {
				isLoggedInBackendless = true;
				isLoggedInTwitter = true;
				startLoginResult(backendlessUser);
			}

			@Override
			public void handleFault(BackendlessFault fault) {
				isLoggedInBackendless = false;
				super.handleFault(fault);
				startLoginResult(fault.toString(), false);
			}
		}, rememberLogin);
	}
	// ------------------------------ end twitter ------------------------------
	</xsl:if>

	<xsl:if test="$facebookLogin">
	// ------------------------------ facebook ------------------------------
	private void loginToBackendlessWithFacebook()
	{
		boolean rememberLogin = rememberLoginBox.isChecked();
		Backendless.UserService.loginWithFacebookSdk(fbAccessToken, new AsyncCallback&lt;BackendlessUser&gt;() {
			@Override
			public void handleResponse(BackendlessUser backendlessUser) {
				isLoggedInBackendless = true;
				startLoginResult(backendlessUser);
			}

			@Override
			public void handleFault(BackendlessFault fault) {
				isLoggedInBackendless = false;
				startLoginResult(fault.toString(), false);
			}
		}, rememberLogin);
	}

	private CallbackManager configureFacebookSDKLogin() {
		loginFacebookButton.setReadPermissions("email");
		// If using in a fragment
		//loginFacebookButton.setFragment(this);

		CallbackManager callbackManager = CallbackManager.Factory.create();

		// Callback registration
		loginFacebookButton.registerCallback(callbackManager, new FacebookCallback&lt;com.facebook.login.LoginResult&gt;() {
			@Override
			public void onSuccess(com.facebook.login.LoginResult loginResult) {
				isLoggedInFacebook = true;
				fbAccessToken = loginResult.getAccessToken().getToken();
				loginToBackendlessWithFacebook();
			}

			@Override
			public void onCancel() {
				// App code
				Log.i("LoginProcess", "loginFacebookButton::onCancel");
				Toast.makeText(MainLogin.this, "Facebook login process cancelled.", Toast.LENGTH_LONG).show();
			}

			@Override
			public void onError(FacebookException exception) {
				isLoggedInFacebook = false;
				fbAccessToken = null;
				String msg = exception.getMessage() + "\nCause:\n" + (exception.getCause() != null ? exception.getCause().getMessage() : "none");
				Toast.makeText(MainLogin.this, msg, Toast.LENGTH_LONG).show();
			}
		});

		return callbackManager;
	}

	private void logoutFromFacebook()
	{
		if (!isLoggedInFacebook)
			return;

		if (AccessToken.getCurrentAccessToken() != null)
			LoginManager.getInstance().logOut();

		isLoggedInFacebook = false;
		fbAccessToken = null;
	}
	// ------------------------------ end facebook ------------------------------
	</xsl:if>

	<xsl:if test="$googleLogin">
	// ------------------------------ google ------------------------------
	private void loginToBackendlessWithGoogle()
	{
		boolean rememberLogin = rememberLoginBox.isChecked();
		Backendless.UserService.loginWithGooglePlusSdk(gpAccessToken, new AsyncCallback&lt;BackendlessUser&gt;() {
			@Override
			public void handleResponse(BackendlessUser backendlessUser) {
				isLoggedInBackendless = true;
				startLoginResult(backendlessUser);
			}

			@Override
			public void handleFault(BackendlessFault fault) {
				startLoginResult(fault.toString(), false);
			}
		}, rememberLogin);
	}

	private void configureGooglePlusSDK()
	{
		GoogleSignInOptions gso = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
				.requestScopes(new Scope(Scopes.PROFILE), new Scope(Scopes.PLUS_ME))
				.requestId()
				.requestIdToken(getString(R.string.gp_WebApp_ClientId))
				.requestServerAuthCode(getString(R.string.gp_WebApp_ClientId), false)
				.requestEmail()
				.build();

		mGoogleApiClient = new GoogleApiClient.Builder(this)
				//.enableAutoManage(this /* FragmentActivity */, this /* OnConnectionFailedListener */)
				//.addOnConnectionFailedListener(this)
				.addApi(Auth.CREDENTIALS_API)
				.addApi(Auth.GOOGLE_SIGN_IN_API, gso)
//				.addScope(new Scope(Scopes.PROFILE))
//				.addScope(new Scope(Scopes.PLUS_ME))
				.build();

		loginGooglePlusButton.setOnClickListener(new View.OnClickListener() {
			@Override
			public void onClick(View v) {
				Intent signInIntent = Auth.GoogleSignInApi.getSignInIntent(mGoogleApiClient);
				startActivityForResult(signInIntent, RC_SIGN_IN);
			}
		});
	}

	private void handleSignInResult(GoogleSignInResult result) {
		//Log.d(TAG, "handleSignInResult:" + result.isSuccess());
		if (result.isSuccess()) {
			isLoggedInGoogle = true;

			//this is old approach to get google access token:
			//final String scopes = "oauth2:" + Scopes.PLUS_LOGIN + " " + Scopes.PLUS_ME + " " + Scopes.PROFILE + " " + Scopes.EMAIL;
			//gpAccessToken = GoogleAuthUtil.getToken(LoginWithGooglePlusSDKActivity.this, result.getSignInAccount().getEmail(), scopes);

			final String gpAuthToken = result.getSignInAccount().getServerAuthCode();
			if (gpAuthToken == null) {
				Toast.makeText(MainLogin.this, "Google didn't return AuthToken.", Toast.LENGTH_LONG).show();
				return;
			}
			Thread t = new Thread(new Runnable() {
				@Override
				public void run() {
					exchangeAuthTokenOnAccessToken(gpAuthToken);

					/***********************************************************************
					 * Now that the login to Google has completed successfully, the code
					 * will login to Backendless by "exchanging" Google's access token
					 * for BackendlessUser. This is done in the loginToBackendlessWithGoogle() method.
					 ***********************************************************************/
					loginToBackendlessWithGoogle();
				}
			});
			t.setDaemon(true);
			t.start();
			//updateUI(true);
		} else {
			// Signed out, show unauthenticated UI.
			gpAccessToken = null;
			isLoggedInGoogle = false;
			String msg = "Unsuccessful Google login.\nStatus message:\n" + result.getStatus().getStatusMessage();
			Toast.makeText(MainLogin.this, msg, Toast.LENGTH_LONG).show();
		}
	}

	private String exchangeAuthTokenOnAccessToken(String gpAuthToken ) {
		GoogleTokenResponse tokenResponse = null;
		try {
			tokenResponse = new GoogleAuthorizationCodeTokenRequest(
					new NetHttpTransport(),
					JacksonFactory.getDefaultInstance(),
					"https://www.googleapis.com/oauth2/v4/token",
					getString(R.string.gp_WebApp_ClientId),
					getString(R.string.gp_WebApp_ClientSecret),
					gpAuthToken,
					"")  // Specify the same redirect URI that you use with your web
					// app. If you don't have a web version of your app, you can
					// specify an empty string.
					.execute();
		} catch (Exception e) {
			Log.e("LoginWithGooglePlus", e.getMessage(), e);
			Toast.makeText(MainLogin.this, "Google didn't exchange AuthToken on AccessToken.\n"+e.getMessage(), Toast.LENGTH_LONG).show();
			return null;
		}

		gpAccessToken = tokenResponse.getAccessToken();
		return gpAccessToken;
	}

	private void logoutFromGoogle()
	{
		AsyncTask.execute(new Runnable() {
			@Override
			public void run() {
				mGoogleApiClient.blockingConnect(10, TimeUnit.SECONDS);
				if (!mGoogleApiClient.isConnected())
				{
					Toast.makeText(MainLogin.this, "Can not sign out from Google plus. No connection. Try later.", Toast.LENGTH_LONG).show();
					return;
				}

				Auth.GoogleSignInApi.signOut(mGoogleApiClient).setResultCallback(
						new ResultCallback&lt;Status&gt;() {
							@Override
							public void onResult(@NonNull Status status) {
								if (!status.isSuccess())
									return;

								isLoggedInGoogle = false;
								gpAccessToken = null;
							}
						});
			}
		});
	}
	// ------------------------------ end google ------------------------------
	</xsl:if>

	@Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		super.onActivityResult(requestCode, resultCode, data);

		<xsl:if test="$googleLogin">
		// google
		// Result returned from launching the Intent from GoogleSignInApi.getSignInIntent(...);
		if (requestCode == RC_SIGN_IN) {
			GoogleSignInResult result = Auth.GoogleSignInApi.getSignInResultFromIntent(data);
			handleSignInResult(result);
			return;
		}
		</xsl:if>

		<xsl:if test="$facebookLogin">
		// facebook
		callbackManager.onActivityResult(requestCode, resultCode, data);
		</xsl:if>
	}
}
    </file>

    <file name="LoginResult.java">
package <xsl:value-of select="$package"/>;
<xsl:value-of select="document('../../userservicedemo/src/LoginResult.java.xml')/text" />
    </file>

    <file name="DefaultCallback.java">
package <xsl:value-of select="$package"/>;
<xsl:value-of select="document('../../userservicedemo/src/DefaultCallback.java.xml')/text" />
    </file>

    <xsl:if test="$backendlessLogin">
    <file name="RegisterActivity.java">
package <xsl:value-of select="$package"/>;
<xsl:value-of select="document('../../userservicedemo/src/RegisterActivity.java.xml')/text" />
    </file>

    <file name="RestorePasswordActivity.java">
package <xsl:value-of select="$package"/>;
<xsl:value-of select="document('../../userservicedemo/src/RestorePasswordActivity.java.xml')/text" />
    </file>
    </xsl:if>

  </folder>

</xsl:template>
</xsl:stylesheet>