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

// AOHealth components (feature/aohealth-components)
export 'src/widgets/eden_progress_ring.dart';
export 'src/widgets/eden_chip.dart';
export 'src/widgets/eden_segmented_control.dart';
export 'src/widgets/eden_settings_tile.dart';

// Form inputs (ported from Rails eden-ui)
export 'src/widgets/eden_textarea.dart';
export 'src/widgets/eden_date_picker.dart';
export 'src/widgets/eden_time_picker.dart';
export 'src/widgets/eden_phone_input.dart';
export 'src/widgets/eden_tag_input.dart';
export 'src/widgets/eden_file_input.dart';
export 'src/widgets/eden_dropzone.dart';
export 'src/widgets/eden_form_group.dart';
export 'src/widgets/eden_filter_dropdown.dart';
export 'src/widgets/eden_color_picker.dart';
export 'src/widgets/eden_range.dart';

// Data display & feedback (ported from Rails eden-ui)
export 'src/widgets/eden_table_toolbar.dart';
export 'src/widgets/eden_activity_timeline.dart';
export 'src/widgets/eden_popover.dart';
export 'src/widgets/eden_status_banner.dart';
export 'src/widgets/eden_bulk_action_bar.dart';
export 'src/widgets/eden_speed_dial.dart';

// Cards & business components (ported from Rails eden-ui)
export 'src/widgets/eden_file_card.dart';
export 'src/widgets/eden_user_card.dart';
export 'src/widgets/eden_plan_card.dart';
export 'src/widgets/eden_event_card.dart';
export 'src/widgets/eden_invoice_item.dart';
export 'src/widgets/eden_order_summary.dart';
export 'src/widgets/eden_transaction_item.dart';

// Charts (lightweight CustomPaint, no external deps)
export 'src/widgets/eden_bar_chart.dart';
export 'src/widgets/eden_line_chart.dart';
export 'src/widgets/eden_doughnut_chart.dart';
export 'src/widgets/eden_mini_chart.dart';

// Business components (promoted from trades-flutter)
export 'src/widgets/eden_status_badge.dart';
export 'src/widgets/eden_urgency_badge.dart';
export 'src/widgets/eden_count_badge.dart';
export 'src/widgets/eden_list_card.dart';
export 'src/widgets/eden_activity_feed_item.dart';
export 'src/widgets/eden_checklist_item.dart';
export 'src/widgets/eden_filter_chip_row.dart';
export 'src/widgets/eden_offline_banner.dart';

// Auth forms (E02-01)
export 'src/widgets/eden_sign_in_form.dart';
export 'src/widgets/eden_sign_up_form.dart';
export 'src/widgets/eden_forgot_password_form.dart';
export 'src/widgets/eden_reset_password_form.dart';
export 'src/widgets/eden_two_factor_form.dart';
export 'src/widgets/eden_edit_profile_form.dart';

// Settings + CRUD + Landing (E02-02)
export 'src/widgets/eden_crud_modal.dart';
export 'src/widgets/eden_delete_confirm.dart';
export 'src/widgets/eden_hero_section.dart';
export 'src/widgets/eden_cta_section.dart';
export 'src/widgets/eden_feature_section.dart';
export 'src/widgets/eden_pricing_section.dart';
export 'src/widgets/eden_faq_section.dart';
export 'src/widgets/eden_testimonial_section.dart';
export 'src/widgets/eden_newsletter_section.dart';

// Media + Utilities (E02-03)
export 'src/widgets/eden_image_gallery.dart';
export 'src/widgets/eden_avatar_upload.dart';
export 'src/widgets/eden_clipboard.dart';
export 'src/widgets/eden_button_group.dart';
export 'src/widgets/eden_device_mockup.dart';

// Layout patterns
export 'src/widgets/eden_split_panel.dart';

// Business patterns (promoted from trades-flutter — Wave 1)
export 'src/widgets/eden_severity_badge.dart';
export 'src/widgets/eden_stat_grid.dart';
export 'src/widgets/eden_pipeline_bar.dart';

// Scaffolds & hierarchy (promoted from trades-flutter — Wave 2)
export 'src/widgets/eden_detail_scaffold.dart';
export 'src/widgets/eden_list_scaffold.dart';
export 'src/widgets/eden_hierarchy_tree.dart';

// Canvas & process components (promoted from trades-flutter — Wave 3)
export 'src/widgets/eden_canvas_toolbar.dart';
export 'src/widgets/eden_swimlane_chart.dart';
export 'src/widgets/eden_rule_tree.dart';
export 'src/widgets/eden_phase_checklist.dart';

// Agent builder components (promoted from trades-flutter — Wave 4)
export 'src/widgets/eden_catalog_picker.dart';
export 'src/widgets/eden_approval_flow.dart';
export 'src/widgets/eden_execution_log.dart';
