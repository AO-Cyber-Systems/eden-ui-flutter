/// Eden UI for Flutter — a component library ported from the Eden UI Rails framework.
library eden_ui;

// Tokens
export 'src/tokens/colors.dart';
export 'src/tokens/spacing.dart';
export 'src/tokens/radii.dart';
export 'src/tokens/shadows.dart';
export 'src/tokens/durations.dart';
export 'src/tokens/typography.dart';

// Theme
export 'src/theme/eden_theme.dart';

// Widgets
export 'src/widgets/eden_button.dart';
export 'src/widgets/eden_card.dart';
export 'src/widgets/eden_badge.dart';
export 'src/widgets/eden_alert.dart';
export 'src/widgets/eden_avatar.dart';
export 'src/widgets/eden_input.dart';
export 'src/widgets/eden_toggle.dart';
export 'src/widgets/eden_progress.dart';
export 'src/widgets/eden_divider.dart';
export 'src/widgets/eden_spinner.dart';
export 'src/widgets/eden_skeleton.dart';
export 'src/widgets/eden_tooltip.dart';
export 'src/widgets/eden_stat_card.dart';
export 'src/widgets/eden_empty_state.dart';
export 'src/widgets/eden_description_list.dart';
export 'src/widgets/eden_data_table.dart';
export 'src/widgets/eden_tabs.dart';
export 'src/widgets/eden_page_header.dart';
export 'src/widgets/eden_section_header.dart';
export 'src/widgets/eden_select.dart';
export 'src/widgets/eden_settings_section.dart';
export 'src/widgets/eden_toast.dart';
export 'src/widgets/eden_stepper.dart';
export 'src/widgets/eden_pagination.dart';
export 'src/widgets/eden_banner.dart';
export 'src/widgets/eden_modal.dart';
export 'src/widgets/eden_drawer.dart';
export 'src/widgets/eden_search_input.dart';
export 'src/widgets/eden_dropdown.dart';
export 'src/widgets/eden_chat_bubble.dart';
export 'src/widgets/eden_accordion.dart';
export 'src/widgets/eden_list_group.dart';
export 'src/widgets/eden_kanban.dart';
export 'src/widgets/eden_calendar.dart';
export 'src/widgets/eden_timeline.dart';
export 'src/widgets/eden_bottom_nav.dart';
export 'src/widgets/eden_breadcrumb.dart';
export 'src/widgets/eden_rating.dart';
export 'src/widgets/eden_code_block.dart';
export 'src/widgets/eden_kbd.dart';
export 'src/widgets/eden_notification_list.dart';
export 'src/widgets/eden_typing_indicator.dart';
export 'src/widgets/eden_task_list.dart';
export 'src/widgets/eden_error_page.dart';
export 'src/widgets/eden_indicator.dart';
export 'src/widgets/eden_carousel.dart';
export 'src/widgets/eden_diagram/eden_diagram_exports.dart';
export 'src/widgets/eden_layout/eden_layout_exports.dart';
export 'src/widgets/support_panel/eden_support_panel_exports.dart';

// Advanced widgets
export 'src/widgets/eden_data_grid.dart';
export 'src/widgets/eden_date_picker.dart';
export 'src/widgets/eden_multi_select.dart';
export 'src/widgets/eden_combobox.dart';
export 'src/widgets/eden_file_upload.dart';
export 'src/widgets/eden_rich_text_editor.dart';
export 'src/widgets/eden_chart.dart';
export 'src/widgets/eden_bottom_sheet.dart';
export 'src/widgets/eden_form.dart';
export 'src/widgets/eden_command_palette.dart';

// Utility & selection widgets
export 'src/widgets/eden_confirm_dialog.dart';
export 'src/widgets/eden_oauth_buttons.dart';
export 'src/widgets/eden_theme_selector.dart';
export 'src/widgets/eden_document_status_badge.dart';
export 'src/widgets/eden_label_picker.dart';
export 'src/widgets/eden_workspace_switcher.dart';

// Messaging
export 'src/widgets/eden_message_bubble.dart';
export 'src/widgets/eden_message_input.dart';
export 'src/widgets/eden_reaction_bar.dart';
export 'src/widgets/eden_link_preview.dart';
export 'src/widgets/eden_attachment_preview.dart';
export 'src/widgets/eden_mention_overlay.dart';

// Content & Navigation
export 'src/widgets/eden_date_separator.dart';
export 'src/widgets/eden_conversation_tile.dart';
export 'src/widgets/eden_markdown_editor.dart';
export 'src/widgets/eden_search_result_card.dart';
export 'src/widgets/eden_sources_footer.dart';
export 'src/widgets/eden_file_list_tile.dart';

// Animations
export 'src/widgets/eden_bouncing_dots.dart';
export 'src/widgets/eden_pulsing_wrapper.dart';
export 'src/widgets/eden_streaming_indicator.dart';

// DevFlow — Infrastructure & DevOps
export 'src/widgets/eden_service_row.dart';
export 'src/widgets/eden_port_row.dart';
export 'src/widgets/eden_domain_row.dart';
export 'src/widgets/eden_certificate_card.dart';
export 'src/widgets/eden_health_check.dart';

// DevFlow — Log & Terminal
export 'src/widgets/eden_log_viewer.dart';
export 'src/widgets/eden_terminal_output.dart';

// DevFlow — Account & Proxy
export 'src/widgets/eden_account_card.dart';
export 'src/widgets/eden_request_log.dart';

// DevFlow — Project & Workflow
export 'src/widgets/eden_project_card.dart';
export 'src/widgets/eden_objective_progress.dart';
export 'src/widgets/eden_workflow_stepper.dart';

// DevFlow — Environment & Config
export 'src/widgets/eden_env_editor.dart';
export 'src/widgets/eden_key_value_table.dart';
export 'src/widgets/eden_secret_field.dart';

// DevFlow — Email & Communication
export 'src/widgets/eden_email_row.dart';
export 'src/widgets/eden_email_viewer.dart';

// DevFlow — Package & Tool Management
export 'src/widgets/eden_package_row.dart';
export 'src/widgets/eden_tool_card.dart';

// DevFlow — Polling & Real-time
export 'src/widgets/eden_polling_container.dart';
export 'src/widgets/eden_live_indicator.dart';

// Git — Commits, Issues & Labels
export 'src/widgets/eden_commit_row.dart';
export 'src/widgets/eden_commit_detail.dart';
export 'src/widgets/eden_issue_row.dart';
export 'src/widgets/eden_issue_detail.dart';
export 'src/widgets/eden_label_badge.dart';
export 'src/widgets/eden_milestone_card.dart';

// DevFlow — CI/CD Pipeline & Deployment
export 'src/widgets/eden_pipeline_graph.dart';
export 'src/widgets/eden_job_card.dart';
export 'src/widgets/eden_job_log.dart';
export 'src/widgets/eden_check_status_row.dart';
export 'src/widgets/eden_environment_card.dart';
export 'src/widgets/eden_deployment_timeline.dart';

// DevFlow — Charts & Roadmaps
export 'src/widgets/eden_contribution_graph.dart';
export 'src/widgets/eden_burndown_chart.dart';
export 'src/widgets/eden_code_frequency_chart.dart';
export 'src/widgets/eden_value_stream_map.dart';
export 'src/widgets/eden_roadmap_view.dart';

// Agent & Planning
export 'src/widgets/eden_agent_run_card.dart';
export 'src/widgets/eden_plan_viewer.dart';
export 'src/widgets/eden_agent_decision_log.dart';

// Project Management
export 'src/widgets/eden_epic_card.dart';
export 'src/widgets/eden_project_table.dart';

// Git — Source Code & Repository
export 'src/widgets/eden_file_tree.dart';
export 'src/widgets/eden_blame_view.dart';
export 'src/widgets/eden_branch_selector.dart';
export 'src/widgets/eden_diff_viewer.dart';
export 'src/widgets/eden_file_diff_header.dart';
export 'src/widgets/eden_suggestion_block.dart';

// Git — Pull Requests & Code Review
export 'src/widgets/eden_pull_request_row.dart';
export 'src/widgets/eden_pull_request_detail.dart';
export 'src/widgets/eden_reviewer_list.dart';
export 'src/widgets/eden_merge_controls.dart';
export 'src/widgets/eden_review_comment.dart';
export 'src/widgets/eden_review_summary.dart';
export 'src/widgets/eden_conversation_thread.dart';

// DevFlow — Security & Compliance
export 'src/widgets/eden_vulnerability_row.dart';
export 'src/widgets/eden_security_alert.dart';
export 'src/widgets/eden_compliance_badge.dart';
export 'src/widgets/eden_feature_flag_row.dart';
export 'src/widgets/eden_incident_card.dart';
export 'src/widgets/eden_error_tracker.dart';
export 'src/widgets/eden_terraform_state_card.dart';

// DevFlow — Releases & Registry
export 'src/widgets/eden_release_card.dart';
export 'src/widgets/eden_changelog_section.dart';
export 'src/widgets/eden_registry_row.dart';
export 'src/widgets/eden_tag_list.dart';

// DevFlow — Collaboration
export 'src/widgets/eden_design_diff_viewer.dart';
export 'src/widgets/eden_discussion_thread.dart';

// Trades — Enterprise UI Components
export 'src/widgets/eden_scheduler.dart';
export 'src/widgets/eden_document_viewer.dart';
export 'src/widgets/eden_signature_pad.dart';
export 'src/widgets/eden_form_wizard.dart';
export 'src/widgets/eden_approval_queue.dart';
export 'src/widgets/eden_photo_gallery.dart';
export 'src/widgets/eden_checklist_builder.dart';
export 'src/widgets/eden_permission_matrix.dart';
export 'src/widgets/eden_sync_indicator.dart';
export 'src/widgets/eden_activity_feed.dart';
export 'src/widgets/eden_map_view.dart';
export 'src/widgets/eden_barcode_scanner.dart';

// Pages
export 'src/pages/eden_profile_page.dart';
export 'src/pages/eden_settings_page.dart';
export 'src/pages/eden_splash_page.dart';
export 'src/pages/eden_onboarding_page.dart';
export 'src/pages/eden_maintenance_page.dart';
export 'src/pages/eden_login_page.dart';
export 'src/pages/eden_signup_page.dart';
export 'src/pages/eden_forgot_password_page.dart';
export 'src/pages/eden_reset_password_page.dart';

// Utils
export 'src/utils/responsive.dart';
