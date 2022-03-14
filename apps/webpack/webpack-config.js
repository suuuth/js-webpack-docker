
// Require path.
const path    = require('path');
const fs      = require('fs');
const webpack = require('webpack');
const MiniCssExtractPlugin    = require("mini-css-extract-plugin");
const TerserJSPlugin          = require('terser-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');

// Configuration object.
const CssUrlRelativePlugin = require('css-url-relative-plugin');

console.log(__dirname);

const cssPath        = '/public/css';
const webpackPath    = '/webpack';
const aliases        = processAliases();
const cssEntryPoints = processCssEntryPoints();
const cssMinifiedEntryPoints = processCssEntryPoints(true);

function processAliases()
{
    let aliases = {};
    let config = JSON.parse(
        fs.readFileSync(webpackPath + '/config.json', 'utf8'),
        true
    );

    for (let [key, value] of Object.entries(config.aliases)) {
        aliases[key] = path.join(__dirname, value);
    }

    return aliases;
}

function processCssEntryPoints(minified = false)
{
    let entryPoints = {};
    let config = JSON.parse(
        fs.readFileSync(webpackPath + '/config.json', 'utf8'),
        true
    );

    for (let [key, value] of Object.entries(config.cssEntryPoints)) {
        if (minified) {
            entryPoints['app.' + key + '.dist.min.js'] = value + '/../config/app.config.js';
        } else {
            entryPoints['app.' + key + '.dist.js'] = value + '/../config/app.config.css';
        }
    }

    return entryPoints;
}

// For development side of the website, generates
// app.css using imported files in app.config.js
var cssConfig = Object.assign(
    buildCssConfig(),
    {
        mode: 'development',
        devtool: 'source-map',
        entry: cssEntryPoints
    }
);

//For production side of the website, generates app.min.css using imported files in app.config.js
//This optimizes the css
var cssConfigMin = Object.assign(
    buildMinCssConfig(),
    {
        mode: 'production',
        entry: cssMinifiedEntryPoints,
        optimization: {
            minimizer: [
                new TerserJSPlugin({}),
                new OptimizeCSSAssetsPlugin({
                    map: {
                        inline: false
                    }
                })
            ],
        },
        plugins: [
            new MiniCssExtractPlugin({
                // Options similar to the same options in webpackOptions.output
                // both options are optional
                filename: "app.min.css",
                chunkFilename: "[id].css",
            }),
            new OptimizeCSSAssetsPlugin({
                cssProcessorOptions: {
                    canPrint: true
                }
            })
        ],
    }
);

function buildCssConfig()
{
// Configuration object.
    return {
        resolve: {},
        output: {
            path: path.resolve(__dirname, cssPath),
            filename: '[name]',
            sourceMapFilename: '[name].map',
        },
        devtool: 'source-map',
        // Setup a loader to transpile down the latest and great JavaScript so older browsers
        // can understand it.
        module: {
            rules: [
                {
                    test: /\.css$/,
                    use: [
                        'style-loader',
                        {
                            loader: 'css-loader',
                            options: {
                                url: true,
                                sourceMap: true,
                                import: true
                            }
                        },
                        {
                            loader: 'postcss-loader',
                            options: {
                                plugins: () => [
                                    require('autoprefixer'),
                                ],
                                sourceMap: false
                            }
                        },
                    ]
                },
                {
                    test: /\.(woff(2)?|ttf|eot|svg)(\?v=\d+\.\d+\.\d+)?$/,
                    use: [
                        "file-loader"
                    ]
                },
                {
                    test: /\.(png|jpe?g|gif)$/i,
                    use: [
                        {
                            loader: 'file-loader',
                        },
                    ],
                },
            ]
        }
    }
}

function buildMinCssConfig()
{
// Configuration object.
    return {
        resolve: {
            alias: aliases
        },
        output: {
            path: path.resolve(__dirname, cssPath),
            filename: '[name]',
            sourceMapFilename: '[name].map'
        },
        devtool: 'source-map',
        // Setup a loader to transpile down the latest and great JavaScript so older browsers
        // can understand it.
        module: {
            rules: [
                {
                    test: /\.css$/,
                    use: [
                        {
                            loader: MiniCssExtractPlugin.loader,
                            options: {
                                publicPathRelativeToSource: true,
                                publicPath: cssPath,
                            }
                        },
                        {
                            loader: 'css-loader',
                            options: {
                                url: false,
                                sourceMap: true
                            }
                        },
                        {
                            loader: 'postcss-loader',
                            options: {
                                plugins: () => [
                                    require('autoprefixer'),
                                ],
                                sourceMap: true
                            }
                        },
                    ]
                },
                {
                    test: /\.(woff(2)?|ttf|eot|svg)(\?v=\d+\.\d+\.\d+)?$/,
                    use: [
                        "file-loader"
                    ]
                },
                {
                    test: /\.(png|jpe?g|gif)$/i,
                    use: [
                        {
                            loader: 'file-loader',
                        },
                    ],
                },
            ]
        }
    }
}


// Export the config object.
module.exports = [cssConfig, cssConfigMin];
