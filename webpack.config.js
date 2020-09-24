const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const webpack = require('webpack');
const CopyPlugin = require('copy-webpack-plugin');

const path = require('path');

const mode = process.env.NODE_ENV || 'development';
const prod = mode === 'production';
const TerserPlugin = require("terser-webpack-plugin");

const dfxJson = require("./dfx.json");


// List of all aliases for canisters. This creates the module alias for
// the `import ... from "ic:canisters/xyz"` where xyz is the name of a
// canister.
const aliases = Object.entries(dfxJson.canisters).reduce(
	(acc, [name, _value]) => {
	  // Get the network name, or `local` by default.
	  const networkName = process.env["DFX_NETWORK"] || "local";
	  const outputRoot = path.join(
		__dirname,
		".dfx",
		networkName,
		"canisters",
		name
	  );
  
	  return {
		...acc,
		["ic:canisters/" + name]: path.join(outputRoot, name + ".js"),
		["ic:idl/" + name]: path.join(outputRoot, name + ".did.js"),
	  };
	},
	{
	  svelte: path.resolve('node_modules', 'svelte')
	}
  );
/**
 * Generate a webpack configuration for a canister.
 */
function generateWebpackConfigForCanister(name, info) {
	if (typeof info.frontend !== "object") {
	  return;
	}
  
	return {
	  mode: "production",
	  entry: {
		index: path.join(__dirname, info.frontend.entrypoint)
	  },
	  devtool: "source-map",
	  optimization: {
		minimize: true,
		minimizer: [new TerserPlugin()],
	  },
	  resolve: {
		alias: aliases,
		extensions: ['.mjs', '.js', '.svelte'],
		mainFields: ['svelte', 'browser', 'module', 'main']
	  },
	  output: {
		path: __dirname + '/dist',
		filename: '[name].js',
		chunkFilename: '[name].[id].js'
	  },
  
	  // Depending in the language or framework you are using for
	  // front-end development, add module loaders to the default
	  // webpack configuration. For example, if you are using React
	  // modules and CSS as described in the "Adding a stylesheet"
	  // tutorial, uncomment the following lines:
	  module: {
		rules: [
			{
				test: /\.svelte$/,
				use: {
					loader: 'svelte-loader',
					options: {
						// emitCss: true,
						hotReload: true
					}
				}
			},
			{
				test: /\.css$/,
				use: [
					/**
					 * MiniCssExtractPlugin doesn't support HMR.
					 * For developing, use 'style-loader' instead.
					 * */
					prod ? MiniCssExtractPlugin.loader : 'style-loader',
					'css-loader'
				]
			}
		]
	  },
	  plugins: [
		new MiniCssExtractPlugin({
			filename: '[name].css'
		}),
		new CopyPlugin({
			patterns: [
			  { from: 'public', to: '' }
			]
		  }),
		new webpack.optimize.LimitChunkCountPlugin({
			maxChunks: 1,
		  }),
	  ]
	}
  }
  
// If you have additional webpack configurations you want to build
//  as part of this configuration, add them to the section below.
module.exports = [
...Object.entries(dfxJson.canisters)
	.map(([name, info]) => {
	return generateWebpackConfigForCanister(name, info);
	})
	.filter((x) => !!x),
];

// module.exports = {
// 	entry: {
// 		bundle: ['./src/main.js']
// 	},
// 	resolve: {
// 		alias: {
// 			svelte: path.resolve('node_modules', 'svelte')
// 		},
// 		extensions: ['.mjs', '.js', '.svelte'],
// 		mainFields: ['svelte', 'browser', 'module', 'main']
// 	},
// 	output: {
// 		path: __dirname + '/public',
// 		filename: '[name].js',
// 		chunkFilename: '[name].[id].js'
// 	},
// 	module: {
// 		rules: [
// 			{
// 				test: /\.svelte$/,
// 				use: {
// 					loader: 'svelte-loader',
// 					options: {
// 						emitCss: true,
// 						hotReload: true
// 					}
// 				}
// 			},
// 			{
// 				test: /\.css$/,
// 				use: [
// 					/**
// 					 * MiniCssExtractPlugin doesn't support HMR.
// 					 * For developing, use 'style-loader' instead.
// 					 * */
// 					prod ? MiniCssExtractPlugin.loader : 'style-loader',
// 					'css-loader'
// 				]
// 			}
// 		]
// 	},
// 	mode,
// 	plugins: [
// 		new MiniCssExtractPlugin({
// 			filename: '[name].css'
// 		})
// 	],
// 	devtool: prod ? false: 'source-map'
// };
